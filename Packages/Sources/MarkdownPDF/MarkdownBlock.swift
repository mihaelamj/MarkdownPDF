import Foundation

public enum MarkdownBlock: Equatable, Sendable {
    case heading(level: Int, content: [MarkdownInline])
    case paragraph([MarkdownInline])
    case blockQuote([MarkdownBlock])
    case unorderedList([ListItem])
    case orderedList(start: Int, items: [ListItem])
    case codeBlock(info: String?, code: String)
    case table(Table)
    case thematicBreak
    case html(String)

    public struct ListItem: Equatable, Sendable {
        public var blocks: [MarkdownBlock]

        public init(blocks: [MarkdownBlock]) {
            self.blocks = blocks
        }
    }

    public struct Table: Equatable, Sendable {
        public var headers: [[MarkdownInline]]
        public var alignments: [Alignment]
        public var rows: [[[MarkdownInline]]]

        public init(
            headers: [[MarkdownInline]],
            alignments: [Alignment],
            rows: [[[MarkdownInline]]],
        ) {
            self.headers = headers
            self.alignments = alignments
            self.rows = rows
        }
    }

    public enum Alignment: Equatable, Sendable {
        case leading
        case center
        case trailing
    }
}
