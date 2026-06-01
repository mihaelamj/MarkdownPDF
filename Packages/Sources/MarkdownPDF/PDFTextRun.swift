import Foundation

struct PDFTextRun {
    var text: String
    var font: StandardFont
    var size: Double
    var color: PDFColor
    var underline: Bool
    var strikethrough: Bool
    var linkDestination: String?

    init(
        text: String,
        font: StandardFont,
        size: Double,
        color: PDFColor = .black,
        underline: Bool = false,
        strikethrough: Bool = false,
        linkDestination: String? = nil,
    ) {
        self.text = PDFTextEncoding.portableText(for: text)
        self.font = font
        self.size = size
        self.color = color
        self.underline = underline
        self.strikethrough = strikethrough
        self.linkDestination = linkDestination
    }

    func width(fontSet: PDFOptions.FontSet) -> Double {
        font.width(of: text, size: size, fontSet: fontSet)
    }
}
