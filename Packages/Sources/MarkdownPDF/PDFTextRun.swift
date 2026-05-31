import Foundation

struct PDFTextRun {
    var text: String
    var font: StandardFont
    var size: Double
    var color: PDFColor
    var underline: Bool
    var strikethrough: Bool

    init(
        text: String,
        font: StandardFont,
        size: Double,
        color: PDFColor = .black,
        underline: Bool = false,
        strikethrough: Bool = false,
    ) {
        self.text = text
        self.font = font
        self.size = size
        self.color = color
        self.underline = underline
        self.strikethrough = strikethrough
    }

    func width() -> Double {
        font.width(of: text, size: size)
    }
}
