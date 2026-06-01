import Foundation

struct PDFDocumentWriter {
    var pageSize: PDFOptions.PageSize
    var fontSet: PDFOptions.FontSet
    var pages: [PDFPageCanvas]
    var images: [PDFImage]
    var title: String?

    func data() -> Data {
        var builder = Builder()
        let catalogRef = builder.reserve()
        let pagesRef = builder.reserve()

        let usedFonts = StandardFont.allCases.filter { font in
            pages.contains { $0.resourceUsage.usesFont(font) }
        }
        let fontResources = Dictionary(uniqueKeysWithValues: usedFonts.map { font in
            let fontObject = PDFFontObject(font: font, fontSet: fontSet)
            return (
                font,
                PDFPageResources.Entry(name: fontObject.resourceName, objectRef: builder.addFont(fontObject)),
            )
        })

        let usedImageNames = Set(pages.flatMap(\.resourceUsage.usedImageXObjectNames))
        let imageResources = Dictionary(uniqueKeysWithValues: images.filter { usedImageNames.contains($0.name) }.map { image in
            let imageXObject = PDFImageXObject(image: image)
            return (
                imageXObject.resourceName,
                imageXObject.resource(objectRef: builder.addImage(imageXObject)),
            )
        })

        func resources(for page: PDFPageCanvas) -> PDFPageResources {
            let pageFonts = page.resourceUsage.usedFonts.compactMap { font in
                fontResources[font]
            }
            let pageXObjects = images.compactMap { image in
                page.resourceUsage.usesImageXObject(named: image.name) ? imageResources[image.name] : nil
            }
            return PDFPageResources(fonts: pageFonts, imageXObjects: pageXObjects)
        }

        var pageRefs: [PDFSyntax.Reference] = []
        for page in pages {
            let contentData = Data(page.commands.utf8)
            let contentRef = builder.addStream(dictionary: PDFSyntax.Dictionary(), data: contentData)
            let annotationRefs = page.linkAnnotations.map { builder.addLinkAnnotation($0) }

            let pageRef = builder.addDictionary(
                PDFPageDictionary(
                    parent: pagesRef,
                    mediaBox: pageSize,
                    resources: resources(for: page).pdfDictionary,
                    contents: contentRef,
                    annotations: annotationRefs,
                ).pdfDictionary,
                style: .multiline,
            )
            pageRefs.append(pageRef)
        }

        builder.set(
            pagesRef,
            .dictionary(PDFDocumentPageTree(kids: pageRefs).pdfDictionary),
        )
        builder.set(
            catalogRef,
            .dictionary(
                PDFDocumentCatalog(
                    pages: pagesRef,
                    displayDocumentTitle: title?.isEmpty == false,
                ).pdfDictionary,
            ),
        )

        return builder.build(root: catalogRef)
    }

    private struct Builder {
        private var registry = PDFObjectRegistry()

        mutating func reserve() -> PDFSyntax.Reference {
            registry.reserve()
        }

        mutating func set(_ ref: PDFSyntax.Reference, _ value: PDFSyntax.Value) {
            set(ref, Data(value.serialized.utf8))
        }

        mutating func set(_ ref: PDFSyntax.Reference, _ value: Data) {
            registry.set(ref, body: value)
        }

        mutating func addDictionary(
            _ dictionary: PDFSyntax.Dictionary,
            style: PDFSyntax.Dictionary.Style = .inline,
        ) -> PDFSyntax.Reference {
            addData(Data(dictionary.serialized(style: style).utf8))
        }

        mutating func addFont(_ fontObject: PDFFontObject) -> PDFSyntax.Reference {
            let descriptorRef = fontObject.fontDescriptor.map { descriptor in
                addDictionary(descriptor.pdfDictionary)
            }
            return addDictionary(fontObject.pdfDictionary(fontDescriptor: descriptorRef))
        }

        mutating func addStream(dictionary: PDFSyntax.Dictionary, data: Data) -> PDFSyntax.Reference {
            addData(PDFSyntax.Stream(dictionary: dictionary, data: data).serialized)
        }

        mutating func addImage(_ image: PDFImageXObject) -> PDFSyntax.Reference {
            addData(image.pdfStream.serialized)
        }

        mutating func addLinkAnnotation(_ annotation: PDFLinkAnnotation) -> PDFSyntax.Reference {
            let minX = annotation.x
            let minY = annotation.y
            let maxX = annotation.x + annotation.width
            let maxY = annotation.y + annotation.height
            return addDictionary(
                PDFSyntax.Dictionary([
                    .init("Type", .pdfName("Annot")),
                    .init("Subtype", .pdfName("Link")),
                    .init(
                        "Rect",
                        .pdfArray([
                            .number(minX),
                            .number(minY),
                            .number(maxX),
                            .number(maxY),
                        ]),
                    ),
                    .init(
                        "Border",
                        .pdfArray([
                            .int(0),
                            .int(0),
                            .int(0),
                        ]),
                    ),
                    .init(
                        "A",
                        .pdfDictionary([
                            .init("S", .pdfName("URI")),
                            .init("URI", .pdfString(annotation.destination.pdfURI)),
                        ]),
                    ),
                ]),
                style: .multiline,
            )
        }

        func build(root: PDFSyntax.Reference) -> Data {
            registry.serializedFile(root: root)
        }

        private mutating func addData(_ data: Data) -> PDFSyntax.Reference {
            registry.add(data)
        }
    }
}

private extension String {
    var pdfURI: String {
        if contains("://") || hasPrefix("mailto:") || hasPrefix("#") || hasPrefix("/") || hasPrefix(".") {
            return self
        }

        if contains("@"), !contains("/") {
            return "mailto:\(self)"
        }

        return self
    }
}
