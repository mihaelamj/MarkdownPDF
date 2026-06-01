import Foundation

public struct PDFOptions: Equatable, Sendable {
    public var pageSize: PageSize
    public var margins: Margins
    public var baseFontSize: Double
    public var fontSet: FontSet
    public var title: String?
    public var tableOfContents: TableOfContents

    public init(
        pageSize: PageSize = .a4,
        margins: Margins = .standard,
        baseFontSize: Double = 11,
        fontSet: FontSet = .pdfBase,
        title: String? = nil,
        tableOfContents: TableOfContents = .disabled,
    ) {
        self.pageSize = pageSize
        self.margins = margins
        self.baseFontSize = baseFontSize
        self.fontSet = fontSet
        self.title = title
        self.tableOfContents = tableOfContents
    }

    public struct PageSize: Equatable, Sendable {
        public var width: Double
        public var height: Double

        public init(width: Double, height: Double) {
            self.width = width
            self.height = height
        }

        public static let a4 = PageSize(width: 595.28, height: 841.89)
        public static let letter = PageSize(width: 612, height: 792)
    }

    public struct Margins: Equatable, Sendable {
        public var top: Double
        public var right: Double
        public var bottom: Double
        public var left: Double

        public init(
            top: Double,
            right: Double,
            bottom: Double,
            left: Double,
        ) {
            self.top = top
            self.right = right
            self.bottom = bottom
            self.left = left
        }

        public static let standard = Margins(top: 54, right: 54, bottom: 54, left: 54)
    }

    public struct FontSet: Equatable, Sendable {
        public var regular: String
        public var bold: String
        public var italic: String
        public var monospaced: String
        public var subtype: String

        public init(
            regular: String,
            bold: String,
            italic: String,
            monospaced: String,
            subtype: String,
        ) {
            self.regular = regular
            self.bold = bold
            self.italic = italic
            self.monospaced = monospaced
            self.subtype = subtype
        }

        public static let appleSystem = FontSet(
            regular: "SFProText-Regular",
            bold: "SFProText-Bold",
            italic: "SFProText-RegularItalic",
            monospaced: "SFMono-Regular",
            subtype: "TrueType",
        )

        public static let pdfBase = FontSet(
            regular: "Helvetica",
            bold: "Helvetica-Bold",
            italic: "Helvetica-Oblique",
            monospaced: "Courier",
            subtype: "Type1",
        )

        public static let pdfBaseMonospaced = FontSet(
            regular: "Courier",
            bold: "Courier-Bold",
            italic: "Courier-Oblique",
            monospaced: "Courier",
            subtype: "Type1",
        )
    }

    /// Controls whether the portable renderer inserts a generated table of contents.
    public struct TableOfContents: Equatable, Sendable {
        public var isEnabled: Bool
        public var title: String
        public var maximumDepth: Int

        public init(
            isEnabled: Bool,
            title: String = "Table of Contents",
            maximumDepth: Int = 6,
        ) {
            self.isEnabled = isEnabled
            self.title = title
            self.maximumDepth = max(1, min(6, maximumDepth))
        }

        public static let disabled = TableOfContents(isEnabled: false)
        public static let enabled = TableOfContents(isEnabled: true)
    }
}
