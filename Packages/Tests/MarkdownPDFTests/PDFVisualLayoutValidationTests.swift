import Foundation
import MarkdownPDF
import Testing

@Suite("PDF visual layout validation")
struct PDFVisualLayoutValidationTests {
    @Test("Generated PDFs do not have overlapping Poppler word boxes")
    func generatedPDFsDoNotHaveOverlappingPopplerWordBoxes() throws {
        let markdown = """
        # Visual validation

        This fixture checks proportional spacing, **bold spacing**, *italic spacing*,
        and `monospaced spacing` on narrow pages.

        | Column | Description |
        |---|---|
        | Alpha | Several words should remain separated. |
        | Beta | Wide letters like WWWWWW and narrow letters like iiiiii both render. |

        The renderer should wrap text without causing adjacent words to collide.
        Another paragraph gives Poppler enough lines to expose vertical spacing
        problems if text positions are too tight.
        """
        let data = try MarkdownPDFRenderer(
            options: PDFOptions(
                pageSize: PDFOptions.PageSize(width: 260, height: 320),
                margins: PDFOptions.Margins(top: 24, right: 22, bottom: 24, left: 22),
                baseFontSize: 10,
            ),
        ).render(markdown: markdown)
        let result = try PDFValidation.pdftotextTSV(data: data, name: "visual-layout")
        try #require(result.exitCode == 0, "pdftotext -tsv failed:\n\(result.output)")

        let layout = try PopplerTextLayout(tsv: result.output)
        let issues = layout.visualLayoutIssues()

        #expect(layout.words.count > 30)
        #expect(
            issues.isEmpty,
            "Poppler text layout has visual issues:\n\(issues.joined(separator: "\n"))",
        )
    }

    @Test("Visual layout validator rejects overlapping words")
    func visualLayoutValidatorRejectsOverlappingWords() throws {
        let layout = try PopplerTextLayout(tsv: """
        level\tpage_num\tpar_num\tblock_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext
        1\t1\t0\t0\t0\t0\t0.000000\t0.000000\t200.000000\t200.000000\t-1\t###PAGE###
        4\t1\t0\t1\t0\t0\t10.000000\t20.000000\t60.000000\t10.000000\t-1\t###LINE###
        5\t1\t0\t1\t0\t0\t10.00\t20.00\t40.00\t10.00\t100\tFirst
        5\t1\t0\t1\t0\t1\t49.00\t20.00\t30.00\t10.00\t100\tSecond
        """)

        #expect(layout.visualLayoutIssues().contains { $0.contains("overlaps") })
    }
}

private struct PopplerTextLayout {
    struct Box: Equatable {
        var level: Int
        var page: Int
        var paragraph: Int
        var block: Int
        var line: Int
        var word: Int
        var left: Double
        var top: Double
        var width: Double
        var height: Double
        var text: String

        var right: Double {
            left + width
        }

        var bottom: Double {
            top + height
        }
    }

    var boxes: [Box]

    var pages: [Box] {
        boxes.filter { $0.level == 1 }
    }

    var lines: [Box] {
        boxes.filter { $0.level == 4 }
    }

    var words: [Box] {
        boxes.filter { $0.level == 5 && !$0.text.isEmpty }
    }

    init(tsv: String) throws {
        boxes = try tsv
            .split(separator: "\n", omittingEmptySubsequences: true)
            .dropFirst()
            .map { line in
                try Self.parse(line: String(line))
            }
    }

    func visualLayoutIssues() -> [String] {
        var issues: [String] = []
        validateBoxesHavePositiveSize(issues: &issues)
        validateWordsFitPageBounds(issues: &issues)
        validateWordsDoNotOverlap(issues: &issues)
        validateLinesDoNotOverlap(issues: &issues)
        return issues
    }

    private func validateBoxesHavePositiveSize(issues: inout [String]) {
        for box in words + lines + pages where box.width <= 0 || box.height <= 0 {
            issues.append("\(boxDescription(box)) has non-positive size")
        }
    }

    private func validateWordsFitPageBounds(issues: inout [String]) {
        let pagesByNumber = Dictionary(uniqueKeysWithValues: pages.map { ($0.page, $0) })
        for word in words {
            guard let page = pagesByNumber[word.page] else {
                issues.append("\(boxDescription(word)) references missing page \(word.page)")
                continue
            }

            if word.left < page.left - tolerance
                || word.top < page.top - tolerance
                || word.right > page.right + tolerance
                || word.bottom > page.bottom + tolerance
            {
                issues.append("\(boxDescription(word)) is outside page bounds")
            }
        }
    }

    private func validateWordsDoNotOverlap(issues: inout [String]) {
        for group in groupedWordsByLine() {
            let sortedWords = group.sorted { left, right in
                if left.left == right.left {
                    return left.word < right.word
                }
                return left.left < right.left
            }

            for (left, right) in zip(sortedWords, sortedWords.dropFirst()) {
                if right.left < left.right - tolerance {
                    issues.append("\(boxDescription(left)) overlaps \(boxDescription(right))")
                }
            }
        }
    }

    private func validateLinesDoNotOverlap(issues: inout [String]) {
        for group in groupedLinesByBlock() {
            let sortedLines = group.sorted { left, right in
                if left.top == right.top {
                    return left.line < right.line
                }
                return left.top < right.top
            }

            for (top, bottom) in zip(sortedLines, sortedLines.dropFirst()) {
                if bottom.top < top.bottom - tolerance {
                    issues.append("\(boxDescription(top)) collides vertically with \(boxDescription(bottom))")
                }
            }
        }
    }

    private func groupedWordsByLine() -> [[Box]] {
        Dictionary(grouping: words) { box in
            "\(box.page):\(box.paragraph):\(box.block):\(box.line)"
        }.values.map(Array.init)
    }

    private func groupedLinesByBlock() -> [[Box]] {
        Dictionary(grouping: lines) { box in
            "\(box.page):\(box.paragraph):\(box.block)"
        }.values.map(Array.init)
    }

    private func boxDescription(_ box: Box) -> String {
        "page \(box.page) paragraph \(box.paragraph) block \(box.block) line \(box.line) word \(box.word) '\(box.text)'"
    }

    private static func parse(line: String) throws -> Box {
        let columns = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard columns.count >= 12,
              let level = Int(columns[0]),
              let page = Int(columns[1]),
              let paragraph = Int(columns[2]),
              let block = Int(columns[3]),
              let lineNumber = Int(columns[4]),
              let word = Int(columns[5]),
              let left = Double(columns[6]),
              let top = Double(columns[7]),
              let width = Double(columns[8]),
              let height = Double(columns[9])
        else {
            throw PDFVisualLayoutValidationError.invalidTSVLine(line)
        }

        return Box(
            level: level,
            page: page,
            paragraph: paragraph,
            block: block,
            line: lineNumber,
            word: word,
            left: left,
            top: top,
            width: width,
            height: height,
            text: columns[11...].joined(separator: "\t"),
        )
    }

    private let tolerance = 0.5
}

private enum PDFVisualLayoutValidationError: Error {
    case invalidTSVLine(String)
}
