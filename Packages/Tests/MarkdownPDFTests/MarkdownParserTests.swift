import MarkdownPDF
import Testing

@Suite("Markdown parser")
struct MarkdownParserTests {
    @Test("Parses headings, inline styles, links, and code")
    func parsesInlineMarkdown() {
        let document = MarkdownParser().parse("""
        # Title

        Text with **strong**, *emphasis*, `code`, ~~strike~~, and [a link](https://example.com).
        """)

        #expect(document.blocks.count == 2)
        #expect(document.blocks.first == .heading(level: 1, content: [.text("Title")]))
    }

    @Test("Parses GitHub style tables")
    func parsesTables() {
        let document = MarkdownParser().parse("""
        | Name | Score |
        |:-----|------:|
        | Ada  | 10    |
        | Lin  | 8     |
        """)

        guard case let .table(table) = document.blocks.first else {
            Issue.record("Expected a table")
            return
        }

        #expect(table.headers.count == 2)
        #expect(table.rows.count == 2)
        #expect(table.alignments == [.leading, .trailing])
    }

    @Test("Parses standalone images")
    func parsesImages() {
        let document = MarkdownParser().parse("![Alt text](image.jpg \"Title\")")

        guard case let .paragraph(inlines) = document.blocks.first,
              case let .image(alt, source, title) = inlines.first
        else {
            Issue.record("Expected an image paragraph")
            return
        }

        #expect(alt == "Alt text")
        #expect(source == "image.jpg")
        #expect(title == "Title")
    }
}
