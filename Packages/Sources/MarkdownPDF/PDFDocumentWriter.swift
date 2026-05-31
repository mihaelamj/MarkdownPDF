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

        let fontRefs = StandardFont.allCases.map { font in
            (font, builder.addFont(font, fontSet: fontSet))
        }

        let imageRefs = images.map { image in
            (image.name, builder.addImage(image))
        }

        var pageRefs: [Int] = []
        for page in pages {
            let contentData = Data(page.commands.utf8)
            let contentRef = builder.addStream(dictionary: "<<", data: contentData)
            let resourceDictionary = resources(fontRefs: fontRefs, imageRefs: imageRefs)
            let pageRef = builder.addString("""
            << /Type /Page
            /Parent \(pagesRef) 0 R
            /MediaBox [0 0 \(format(pageSize.width)) \(format(pageSize.height))]
            /Resources \(resourceDictionary)
            /Contents \(contentRef) 0 R >>
            """)
            pageRefs.append(pageRef)
        }

        let kids = pageRefs.map { "\($0) 0 R" }.joined(separator: " ")
        builder.set(
            pagesRef,
            "<< /Type /Pages /Kids [\(kids)] /Count \(pageRefs.count) >>",
        )

        var catalog = "<< /Type /Catalog /Pages \(pagesRef) 0 R"
        if let title, !title.isEmpty {
            catalog += " /ViewerPreferences << /DisplayDocTitle true >>"
        }
        catalog += " >>"
        builder.set(catalogRef, catalog)

        return builder.build(root: catalogRef)
    }

    private func resources(
        fontRefs: [(StandardFont, Int)],
        imageRefs: [(String, Int)],
    ) -> String {
        let fonts = fontRefs
            .map { "/\($0.0.rawValue) \($0.1) 0 R" }
            .joined(separator: " ")
        let xObjects = imageRefs
            .map { "/\($0.0) \($0.1) 0 R" }
            .joined(separator: " ")

        if xObjects.isEmpty {
            return "<< /Font << \(fonts) >> >>"
        }

        return "<< /Font << \(fonts) >> /XObject << \(xObjects) >> >>"
    }

    private struct Builder {
        private var objects: [Data?] = []

        mutating func reserve() -> Int {
            objects.append(nil)
            return objects.count
        }

        mutating func set(_ ref: Int, _ value: String) {
            objects[ref - 1] = Data(value.utf8)
        }

        mutating func addString(_ value: String) -> Int {
            objects.append(Data(value.utf8))
            return objects.count
        }

        mutating func addFont(
            _ font: StandardFont,
            fontSet: PDFOptions.FontSet,
        ) -> Int {
            let baseName = font.baseName(in: fontSet).pdfName
            if font.subtype(in: fontSet) == "Type1" {
                return addString("<< /Type /Font /Subtype /Type1 /BaseFont /\(baseName) /Encoding /WinAnsiEncoding >>")
            }

            let descriptorRef = addString("""
            << /Type /FontDescriptor
            /FontName /\(baseName)
            /Flags 32
            /FontBBox [-200 -250 1200 1000]
            /ItalicAngle \(font.italicAngle)
            /Ascent 900
            /Descent -220
            /CapHeight 700
            /StemV 80 >>
            """)
            let widths = Array(repeating: String(font.nominalWidth), count: 95).joined(separator: " ")
            return addString("""
            << /Type /Font
            /Subtype /TrueType
            /BaseFont /\(baseName)
            /Encoding /WinAnsiEncoding
            /FirstChar 32
            /LastChar 126
            /Widths [\(widths)]
            /FontDescriptor \(descriptorRef) 0 R >>
            """)
        }

        mutating func addStream(dictionary: String, data: Data) -> Int {
            var object = Data()
            object.appendString("\(dictionary) /Length \(data.count) >>\nstream\n")
            object.append(data)
            object.appendString("\nendstream")
            objects.append(object)
            return objects.count
        }

        mutating func addImage(_ image: PDFImage) -> Int {
            var dictionary = """
            << /Type /XObject
            /Subtype /Image
            /Width \(image.width)
            /Height \(image.height)
            /ColorSpace \(image.colorSpace)
            /BitsPerComponent \(image.bitsPerComponent)
            /Filter \(image.filter)
            """
            if let decodeParms = image.decodeParms {
                dictionary += "\n/DecodeParms \(decodeParms)"
            }
            dictionary += "\n"

            return addStream(dictionary: dictionary, data: image.data)
        }

        func build(root: Int) -> Data {
            var output = Data()
            output.appendString("%PDF-1.4\n%\u{00E2}\u{00E3}\u{00CF}\u{00D3}\n")
            var offsets = [0]

            for (offset, object) in objects.enumerated() {
                offsets.append(output.count)
                output.appendString("\(offset + 1) 0 obj\n")
                output.append(object ?? Data("<<>>".utf8))
                output.appendString("\nendobj\n")
            }

            let xrefStart = output.count
            output.appendString("xref\n0 \(objects.count + 1)\n")
            output.appendString("0000000000 65535 f \n")
            for offset in offsets.dropFirst() {
                output.appendString(String(format: "%010d 00000 n \n", offset))
            }
            output.appendString("""
            trailer
            << /Size \(objects.count + 1) /Root \(root) 0 R >>
            startxref
            \(xrefStart)
            %%EOF
            """)

            return output
        }
    }
}

private extension String {
    var pdfName: String {
        replacingOccurrences(of: " ", with: "#20")
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
