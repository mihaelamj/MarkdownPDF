import Foundation
import MarkdownPDF
import Testing

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
