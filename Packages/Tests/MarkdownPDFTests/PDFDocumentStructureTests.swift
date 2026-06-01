import Foundation
@testable import MarkdownPDF
import Testing

@Suite("PDF document structure")
struct PDFDocumentStructureTests {
    @Test("Serializes catalog dictionary")
    func serializesCatalogDictionary() {
        let catalog = PDFDocumentCatalog(
            pages: PDFSyntax.Reference(objectNumber: 2),
            displayDocumentTitle: true,
        )

        #expect(
            catalog.pdfDictionary.serialized()
                == "<< /Type /Catalog /Pages 2 0 R /ViewerPreferences << /DisplayDocTitle true >> >>",
        )
    }

    @Test("Serializes flat page tree")
    func serializesFlatPageTree() {
        let pageTree = PDFDocumentPageTree(kids: [
            PDFSyntax.Reference(objectNumber: 5),
            PDFSyntax.Reference(objectNumber: 6),
        ])

        #expect(pageTree.pdfDictionary.serialized() == "<< /Type /Pages /Kids [5 0 R 6 0 R] /Count 2 >>")
    }

    @Test("Serializes page dictionary with canonical keys")
    func serializesPageDictionaryWithCanonicalKeys() {
        let page = PDFPageDictionary(
            parent: PDFSyntax.Reference(objectNumber: 2),
            mediaBox: PDFOptions.PageSize(width: 300, height: 400),
            resources: PDFSyntax.Dictionary([
                .init(
                    "Font",
                    .pdfDictionary([
                        .init("F1", .reference(PDFSyntax.Reference(objectNumber: 3))),
                    ]),
                ),
            ]),
            contents: PDFSyntax.Reference(objectNumber: 4),
            annotations: [PDFSyntax.Reference(objectNumber: 5)],
        )

        #expect(
            page.pdfDictionary.serialized(style: .multiline)
                == """
                << /Type /Page
                /Parent 2 0 R
                /MediaBox [0 0 300 400]
                /Resources << /Font << /F1 3 0 R >> >>
                /Contents 4 0 R
                /Annots [5 0 R] >>
                """,
        )
    }

    @Test("Omits empty annotation array")
    func omitsEmptyAnnotationArray() {
        let page = PDFPageDictionary(
            parent: PDFSyntax.Reference(objectNumber: 2),
            mediaBox: PDFOptions.PageSize(width: 300, height: 400),
            resources: PDFSyntax.Dictionary(),
            contents: PDFSyntax.Reference(objectNumber: 4),
            annotations: [],
        )

        #expect(!page.pdfDictionary.serialized(style: .multiline).contains("/Annots"))
    }

    @Test("Serializes page resources from typed entries")
    func serializesPageResourcesFromTypedEntries() {
        let resources = PDFPageResources(
            fonts: [
                PDFPageResources.Entry(name: "F2", objectRef: PDFSyntax.Reference(objectNumber: 3)),
            ],
            imageXObjects: [
                PDFPageResources.Entry(name: "Im1", objectRef: PDFSyntax.Reference(objectNumber: 4)),
            ],
            formXObjects: [
                PDFPageResources.Entry(name: "Fm1", objectRef: PDFSyntax.Reference(objectNumber: 5)),
            ],
            extGStates: [
                PDFPageResources.Entry(name: "GS1", objectRef: PDFSyntax.Reference(objectNumber: 6)),
            ],
            patterns: [
                PDFPageResources.Entry(name: "P1", objectRef: PDFSyntax.Reference(objectNumber: 7)),
            ],
        )

        #expect(
            resources.pdfDictionary.serialized()
                == "<< /ExtGState << /GS1 6 0 R >> /Font << /F2 3 0 R >> /XObject << /Im1 4 0 R /Fm1 5 0 R >> /Pattern << /P1 7 0 R >> >>",
        )
    }

    @Test("Omits unused resource namespaces")
    func omitsUnusedResourceNamespaces() {
        let resources = PDFPageResources(
            fonts: [
                PDFPageResources.Entry(name: "F1", objectRef: PDFSyntax.Reference(objectNumber: 3)),
            ],
        )

        #expect(resources.pdfDictionary.serialized() == "<< /Font << /F1 3 0 R >> >>")
    }

    @Test("Serializes PDF base font object without descriptor or embedded font file")
    func serializesPDFBaseFontObjectWithoutDescriptorOrEmbeddedFontFile() {
        let font = PDFFontObject(font: .helvetica, fontSet: .pdfBase)
        let dictionary = font.pdfDictionary(fontDescriptor: nil).serialized()

        #expect(font.resourceName == "F1")
        #expect(font.fontDescriptor == nil)
        #expect(font.metrics == nil)
        #expect(dictionary == "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")
        #expect(!dictionary.contains("/FontDescriptor"))
        #expect(!dictionary.contains("/FontFile"))
        #expect(!dictionary.contains("/ToUnicode"))
    }

    @Test("Serializes unembedded TrueType font object from typed metrics and descriptor")
    func serializesUnembeddedTrueTypeFontObjectFromTypedMetricsAndDescriptor() throws {
        let font = PDFFontObject(font: .helveticaBold, fontSet: .appleSystem)
        let descriptor = try #require(font.fontDescriptor)
        let descriptorText = descriptor.pdfDictionary.serialized()
        let fontText = font.pdfDictionary(
            fontDescriptor: PDFSyntax.Reference(objectNumber: 8),
        ).serialized()

        #expect(font.resourceName == "F2")
        #expect(font.metrics?.firstCharacter == 32)
        #expect(font.metrics?.lastCharacter == 126)
        #expect(descriptorText.contains("/Type /FontDescriptor"))
        #expect(descriptorText.contains("/FontName /SFProText-Bold"))
        #expect(!descriptorText.contains("/FontFile"))
        #expect(fontText.contains("/Subtype /TrueType"))
        #expect(fontText.contains("/BaseFont /SFProText-Bold"))
        #expect(fontText.contains("/FirstChar 32 /LastChar 126"))
        #expect(fontText.contains("/Widths [278 333 474 556"))
        #expect(fontText.contains("/FontDescriptor 8 0 R"))
        #expect(!fontText.contains("/FontFile"))
    }

    @Test("Renderer font model keeps custom non-Type1 font sets on simple TrueType output")
    func rendererFontModelKeepsCustomNonType1FontSetsOnSimpleTrueTypeOutput() {
        let customCompositeNameSet = PDFOptions.FontSet(
            regular: "Portable-Regular",
            bold: "Portable-Bold",
            italic: "Portable-Italic",
            monospaced: "Portable-Mono",
            subtype: "Type0",
        )
        let font = PDFFontObject(font: .helvetica, fontSet: customCompositeNameSet)

        #expect(font.subtype == "TrueType")
        #expect(font.fontDescriptor != nil)
        #expect(font.metrics != nil)
        #expect(font.descendantFonts.isEmpty)
        #expect(font.toUnicodeMap == nil)
    }

    @Test("Font descriptor keeps embedded font file reference as explicit future hook")
    func fontDescriptorKeepsEmbeddedFontFileReferenceAsExplicitFutureHook() {
        let descriptor = PDFFontDescriptor(
            fontName: "PortableTrueType",
            italicAngle: 0,
            embeddedFontFile: .trueType(PDFSyntax.Reference(objectNumber: 9)),
        )

        #expect(descriptor.pdfDictionary.serialized().contains("/FontFile2 9 0 R"))
    }

    @Test("Font object keeps composite font references as explicit future hooks")
    func fontObjectKeepsCompositeFontReferencesAsExplicitFutureHooks() {
        let font = PDFFontObject(
            resourceName: "F9",
            baseName: "PortableCIDFont",
            subtype: "Type0",
            encoding: "Identity-H",
            descendantFonts: [PDFSyntax.Reference(objectNumber: 10)],
            toUnicodeMap: PDFSyntax.Reference(objectNumber: 11),
        )

        let dictionary = font.pdfDictionary(fontDescriptor: nil).serialized()

        #expect(dictionary.contains("/Subtype /Type0"))
        #expect(dictionary.contains("/Encoding /Identity-H"))
        #expect(dictionary.contains("/DescendantFonts [10 0 R]"))
        #expect(dictionary.contains("/ToUnicode 11 0 R"))
    }

    @Test("Draw commands populate typed page resource usage")
    func drawCommandsPopulateTypedPageResourceUsage() {
        let canvas = PDFPageCanvas()

        canvas.drawTextRun(
            PDFTextRun(text: "Heading", font: .helveticaBold, size: 12),
            x: 20,
            y: 100,
            fontSet: .pdfBase,
        )
        canvas.drawImage(name: "Im1", x: 20, y: 20, width: 40, height: 30)

        #expect(canvas.resourceUsage.usedFonts == [.helveticaBold])
        #expect(canvas.resourceUsage.usedImageXObjectNames == ["Im1"])
        #expect(canvas.commands.contains("/F2 12 Tf"))
        #expect(canvas.commands.contains("/Im1 Do"))
    }

    @Test("Renderer keeps deterministic document spine object order")
    func rendererKeepsDeterministicDocumentSpineObjectOrder() throws {
        let data = try MarkdownPDFRenderer().render(markdown: "Hello from MarkdownPDF.")
        let objects = PDFInspector(data).indirectObjects

        #expect(objects.map(\.number) == [1, 2, 3, 4, 5])
        let catalog = try #require(objects.first { $0.number == 1 })
        let pages = try #require(objects.first { $0.number == 2 })
        let font = try #require(objects.first { $0.number == 3 })
        let content = try #require(objects.first { $0.number == 4 })
        let page = try #require(objects.first { $0.number == 5 })

        #expect(catalog.content == "<< /Type /Catalog /Pages 2 0 R >>")
        #expect(pages.content == "<< /Type /Pages /Kids [5 0 R] /Count 1 >>")
        #expect(font.content.contains("/Type /Font"))
        #expect(content.isStream)
        #expect(page.content.contains("<< /Type /Page\n"))
    }

    @Test("Renderer keeps deterministic font resource order")
    func rendererKeepsDeterministicFontResourceOrder() throws {
        let data = try MarkdownPDFRenderer().render(markdown: "Regular **Bold** *Italic* `code`")
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("/Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R /F4 6 0 R >>"))
    }
}
