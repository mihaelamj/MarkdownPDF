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
        #expect(text.contains("/BaseFont /Courier"))
        #expect(!text.contains("/FontFile"))
        #expect(text.contains("xref"))
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
}
