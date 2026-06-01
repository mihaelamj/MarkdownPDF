import Foundation
import MarkdownPDF
import MarkdownPDFLinux
import Testing

#if canImport(MarkdownPDFMac)
    import MarkdownPDFMac
#endif

@Suite("PDF renderer")
struct MarkdownPDFRendererTests {
    @Test("Renders a compact PDF with base fonts and no embedded fonts")
    func rendersPDF() throws {
        let markdown = """
        # Jane Doe

        Swift engineer.

        | Skill | Level |
        |---|---:|
        | Swift | 10 |

        Use `markdownpdf`.

        - Linux
        - PDF
        """

        let data = try MarkdownPDFRenderer().render(markdown: markdown)
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.hasPrefix("%PDF-1.4"))
        #expect(text.contains("/BaseFont /Helvetica"))
        #expect(text.contains("/BaseFont /Courier"))
        #expect(!text.contains("/FontFile"))
        #expect(text.contains("xref"))
    }

    @Test("Writes xref entries that point at PDF objects")
    func writesValidXrefOffsets() throws {
        let data = try MarkdownPDFRenderer().render(markdown: "# Title\n\nBody text.")
        let inspector = PDFInspector(data)

        #expect(inspector.hasValidXrefOffsets())
    }

    @Test("Linux product renders with portable renderer")
    func linuxProductRendersPDF() throws {
        let data = try MarkdownPDFLinuxRenderer().render(markdown: "# Linux\n\nPortable output.")
        let inspector = PDFInspector(data)

        #expect(inspector.text.hasPrefix("%PDF-1.4"))
        #expect(inspector.hasValidXrefOffsets())
    }

    #if canImport(MarkdownPDFMac)
        @Test("Mac product renders through macOS entry point")
        func macProductRendersPDF() throws {
            let data = try MarkdownPDFMacRenderer().render(markdown: "# Mac\n\nPlatform output.")
            let inspector = PDFInspector(data)

            #expect(inspector.text.hasPrefix("%PDF-1.4"))
            #expect(!inspector.text.contains("/FontFile"))
            #expect(inspector.hasValidXrefOffsets())
        }
    #endif

    @Test("Writes stream lengths that match emitted bytes")
    func writesMatchingStreamLengths() throws {
        let data = try MarkdownPDFRenderer().render(markdown: """
        # Title

        Body text with [a link](https://example.com/docs).
        """)
        let inspector = PDFInspector(data)

        #expect(inspector.streamLengthsMatch())
    }

    @Test("Writes minimal canonical PDF for one text page")
    func writesMinimalCanonicalPDFForOneTextPage() throws {
        let data = try MarkdownPDFRenderer().render(markdown: "Hello from MarkdownPDF.")
        let inspector = PDFInspector(data)

        #expect(inspector.text.hasPrefix("%PDF-1.4"))
        #expect(inspector.text.hasSuffix("%%EOF"))
        #expect(inspector.pageCount == 1)
        #expect(inspector.indirectObjectCount == 5)
        #expect(inspector.streams.count == 1)
        #expect(inspector.hasValidXrefOffsets())
        #expect(inspector.streamLengthsMatch())
        #expect(inspector.text.contains("<< /Type /Catalog /Pages 2 0 R >>"))
        #expect(inspector.text.contains("<< /Type /Pages /Kids [5 0 R] /Count 1 >>"))
        #expect(inspector.text.contains("/Resources << /Font << /F1 3 0 R >> >>"))
        #expect(inspector.text.contains("trailer\n<< /Size 6 /Root 1 0 R >>"))
        #expect(!inspector.text.contains("/BaseFont /Helvetica-Bold"))
        #expect(!inspector.text.contains("/BaseFont /Helvetica-Oblique"))
        #expect(!inspector.text.contains("/BaseFont /Courier"))
        #expect(!inspector.text.contains("/XObject"))
        #expect(!inspector.text.contains("/Annots"))
        #expect(!inspector.text.contains("/ViewerPreferences"))
        #expect(!inspector.text.contains("/FontFile"))
    }

    @Test("Writes deterministic page resource dictionaries")
    func writesDeterministicPageResourceDictionaries() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownPDFTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let imageURL = directory.appendingPathComponent("image.jpg")
        try minimalJPEG().write(to: imageURL)

        let data = try MarkdownPDFRenderer().render(
            markdown: "# Image\n\n![pixel](image.jpg)",
            assetsBaseURL: directory,
        )
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("/Resources << /Font << /F2 3 0 R >> /XObject << /Im1 4 0 R >> >>"))
    }

    @Test("Reports page count and link annotations in generated PDF")
    func reportsPagesAndLinkAnnotations() throws {
        let longBody = Array(
            repeating: "This paragraph forces the renderer to continue onto another page.",
            count: 24,
        ).joined(separator: "\n\n")
        let data = try MarkdownPDFRenderer(
            options: PDFOptions(
                pageSize: PDFOptions.PageSize(width: 220, height: 180),
                margins: PDFOptions.Margins(top: 20, right: 20, bottom: 20, left: 20),
                baseFontSize: 10,
            ),
        ).render(markdown: "[Docs](https://example.com/docs)\n\n\(longBody)")
        let inspector = PDFInspector(data)

        #expect(inspector.pageCount > 1)
        #expect(inspector.linkAnnotationCount == 1)
    }

    @Test("Escapes literal strings in content streams")
    func escapesLiteralStrings() throws {
        let data = try MarkdownPDFRenderer().render(
            markdown: #"Text (with parens) and slash \ here."#,
        )
        let streamBodies = PDFInspector(data).streams.map(\.body).joined(separator: "\n")

        #expect(streamBodies.contains(#"(\(with "#))
        #expect(streamBodies.contains(#"parens\) "#))
        #expect(streamBodies.contains(#"(\\ )"#))
    }

    @Test("Supports monospaced PDF base font set")
    func supportsMonospacedPDFBaseFontSet() throws {
        let markdown = """
        # Jane Doe

        Swift engineer.
        """
        let data = try MarkdownPDFRenderer(
            options: PDFOptions(fontSet: .pdfBaseMonospaced),
        ).render(markdown: markdown)
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("/BaseFont /Courier"))
        #expect(!text.contains("/FontFile"))
    }

    @Test("Uses proportional metrics for PDF base fonts")
    func usesProportionalMetricsForPDFBaseFonts() throws {
        let options = PDFOptions(
            pageSize: PDFOptions.PageSize(width: 140, height: 220),
            margins: PDFOptions.Margins(top: 20, right: 20, bottom: 20, left: 20),
            baseFontSize: 10,
            fontSet: .pdfBase,
        )

        let narrowData = try MarkdownPDFRenderer(options: options).render(markdown: "iiiiiiiiii iiiiiiiiii iiiiiiiiii")
        let wideData = try MarkdownPDFRenderer(options: options).render(markdown: "WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW")

        let narrowLineCount = textLineYCoordinates(in: String(decoding: narrowData, as: UTF8.self)).count
        let wideLineCount = textLineYCoordinates(in: String(decoding: wideData, as: UTF8.self)).count

        #expect(narrowLineCount == 1)
        #expect(wideLineCount > narrowLineCount)
    }

    @Test("Writes proportional widths for Apple system TrueType font dictionaries")
    func writesProportionalWidthsForAppleSystemTrueTypeFontDictionaries() throws {
        let data = try MarkdownPDFRenderer(
            options: PDFOptions(fontSet: .appleSystem),
        ).render(markdown: "# WWW\n\nRegular\n\n**Bold**\n\n`code`")
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("/BaseFont /SFProText-Regular"))
        #expect(text.contains("/BaseFont /SFProText-Bold"))
        #expect(text.contains("/BaseFont /SFMono-Regular"))
        #expect(text.contains("/Widths [278 278 355 556"))
        #expect(text.contains("/Widths [278 333 474 556"))
        #expect(text.contains("/Widths [600 600 600 600"))
        #expect(!text.contains("/FontFile"))
    }

    @Test("Renders Markdown links as PDF URI annotations")
    func rendersLinkAnnotations() throws {
        let markdown = """
        [Example](https://example.com/docs) and <person@example.com>
        """

        let data = try MarkdownPDFRenderer().render(markdown: markdown)
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("/Annots ["))
        #expect(text.contains("/Subtype /Link"))
        #expect(text.contains("/S /URI"))
        #expect(text.contains("/URI (https://example.com/docs)"))
        #expect(text.contains("/URI (mailto:person@example.com)"))
    }

    @Test("Writes heading destinations, outlines, internal links, and metadata")
    func writesHeadingDestinationsOutlinesInternalLinksAndMetadata() throws {
        let markdown = """
        # Intro

        [Jump to details](#details) and [External](https://example.com).

        ## Details

        Body text.

        # Intro

        Duplicate heading.
        """
        let data = try MarkdownPDFRenderer(
            options: PDFOptions(title: "Navigation Article"),
        ).render(markdown: markdown)
        let inspector = PDFInspector(data)

        #expect(inspector.hasDocumentMetadata)
        #expect(inspector.outlineItemCount == 3)
        #expect(Set(inspector.namedDestinationNames) == ["intro", "details", "intro-2"])
        #expect(inspector.text.contains("/Outlines "))
        #expect(inspector.text.contains("/Names << /Dests"))
        #expect(inspector.text.contains("/Dest (details)"))
        #expect(inspector.text.contains("/URI (https://example.com)"))
        #expect(
            inspector.canonicalStructureIssues().isEmpty,
            "Canonical PDF structure failed:\n\(inspector.canonicalStructureReport())",
        )
    }

    @Test("Keeps unknown fragment links as URI annotations")
    func keepsUnknownFragmentLinksAsURIAnnotations() throws {
        let data = try MarkdownPDFRenderer().render(markdown: "[Missing](#Missing%20Section)")
        let inspector = PDFInspector(data)

        #expect(inspector.namedDestinationNames.isEmpty)
        #expect(inspector.text.contains("/URI (#Missing%20Section)"))
        #expect(!inspector.text.contains("/Dest (missing-section)"))
        #expect(
            inspector.canonicalStructureIssues().isEmpty,
            "Canonical PDF structure failed:\n\(inspector.canonicalStructureReport())",
        )
    }

    @Test("Normalizes internal fragment links to heading destination names")
    func normalizesInternalFragmentLinksToHeadingDestinationNames() throws {
        let data = try MarkdownPDFRenderer().render(markdown: """
        # Report Section

        [Jump](#Report%20Section)
        """)
        let inspector = PDFInspector(data)

        #expect(inspector.namedDestinationNames == ["report-section"])
        #expect(inspector.text.contains("/Dest (report-section)"))
        #expect(!inspector.text.contains("/URI (#Report%20Section)"))
        #expect(
            inspector.canonicalStructureIssues().isEmpty,
            "Canonical PDF structure failed:\n\(inspector.canonicalStructureReport())",
        )
    }

    @Test("Keeps section headings with first child content")
    func keepsSectionHeadingsWithFirstChildContent() throws {
        let markdown = """
        # Intro

        Line one

        ## Projects

        ### DocHarbor

        Summary line
        """
        let options = PDFOptions(
            pageSize: PDFOptions.PageSize(width: 300, height: 220),
            margins: PDFOptions.Margins(top: 20, right: 20, bottom: 20, left: 20),
            baseFontSize: 10,
        )
        let data = try MarkdownPDFRenderer(options: options).render(markdown: markdown)
        let text = String(decoding: data, as: UTF8.self)
        let streams = contentStreams(in: text)
        let projectsStream = streams.first { $0.contains("(Projects)") }

        #expect(streams.count >= 2)
        #expect(projectsStream?.contains("(DocHarbor)") == true)
        #expect(projectsStream?.contains("(Summary )") == true)
        #expect(projectsStream?.contains("(line)") == true)
    }

    @Test("Embeds local JPEG images")
    func embedsJPEGImages() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownPDFTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let imageURL = directory.appendingPathComponent("image.jpg")
        try minimalJPEG().write(to: imageURL)

        let data = try MarkdownPDFRenderer().render(
            markdown: "![pixel](image.jpg)",
            assetsBaseURL: directory,
        )
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("/Subtype /Image"))
        #expect(text.contains("/DCTDecode"))
    }

    @Test("Embeds local PNG images")
    func embedsPNGImages() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownPDFTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let imageURL = directory.appendingPathComponent("image.png")
        try minimalPNG().write(to: imageURL)

        let data = try MarkdownPDFRenderer().render(
            markdown: "![pixel](image.png)",
            assetsBaseURL: directory,
        )
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.contains("/Subtype /Image"))
        #expect(text.contains("/FlateDecode"))
        #expect(text.contains("/DecodeParms << /Predictor 15 /Colors 3 /BitsPerComponent 8 /Columns 1 >>"))

        let qpdf = try PDFValidation.qpdfCheck(data: data, name: "png-image")
        #expect(qpdf.exitCode == 0, "qpdf --check failed for PNG image PDF:\n\(qpdf.output)")

        let render = try PDFValidation.pdftoppmPNG(data: data, name: "png-image")
        let pngData = try? Data(contentsOf: render.pngURL)
        let dimensions = PDFValidation.pngDimensions(in: pngData)
        #expect(render.result.exitCode == 0, "pdftoppm failed for PNG image PDF:\n\(render.result.output)")
        #expect((dimensions?.width ?? 0) > 0)
        #expect((dimensions?.height ?? 0) > 0)
    }

    @Test("Reuses local image XObjects by source")
    func reusesLocalImageXObjectsBySource() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownPDFTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let imageURL = directory.appendingPathComponent("image.png")
        try minimalPNG().write(to: imageURL)

        let data = try MarkdownPDFRenderer().render(
            markdown: """
            ![first](image.png)

            ![second](image.png)
            """,
            assetsBaseURL: directory,
        )
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.components(separatedBy: "/Subtype /Image").count - 1 == 1)
        #expect(text.components(separatedBy: "/Im1 Do").count - 1 == 2)
        #expect(!text.contains("/Im2"))
    }

    private func minimalJPEG() -> Data {
        Data([
            0xFF, 0xD8,
            0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
            0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01, 0x00, 0x01, 0x03, 0x01, 0x11, 0x00, 0x02, 0x11, 0x00, 0x03, 0x11, 0x00,
            0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00,
            0x00,
            0xFF, 0xD9,
        ])
    }

    private func minimalPNG() -> Data {
        Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D,
            0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x01,
            0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00,
            0x90, 0x77, 0x53, 0xDE,
            0x00, 0x00, 0x00, 0x0F,
            0x49, 0x44, 0x41, 0x54,
            0x78, 0x01, 0x01, 0x04, 0x00, 0xFB, 0xFF,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x04, 0x00, 0x01,
            0x65, 0x49, 0xC3, 0x60,
            0x00, 0x00, 0x00, 0x00,
            0x49, 0x45, 0x4E, 0x44,
            0xAE, 0x42, 0x60, 0x82,
        ])
    }

    private func contentStreams(in text: String) -> [String] {
        text.components(separatedBy: "stream\n")
            .dropFirst()
            .compactMap { component in
                component.components(separatedBy: "\nendstream").first
            }
    }

    private func textLineYCoordinates(in text: String) -> Set<String> {
        Set(
            text.components(separatedBy: "\n").compactMap { line in
                guard line.hasPrefix("BT "),
                      let tfRange = line.range(of: " Tf "),
                      let tdRange = line.range(of: " Td", range: tfRange.upperBound ..< line.endIndex)
                else {
                    return nil
                }

                let coordinates = line[tfRange.upperBound ..< tdRange.lowerBound].split(separator: " ")
                return coordinates.last.map(String.init)
            },
        )
    }
}
