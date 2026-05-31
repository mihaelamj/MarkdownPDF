import Foundation

struct PDFColor: Equatable {
    var red: Double
    var green: Double
    var blue: Double

    static let black = PDFColor(red: 0, green: 0, blue: 0)
    static let link = PDFColor(red: 0.05, green: 0.24, blue: 0.62)
    static let gray = PDFColor(red: 0.35, green: 0.35, blue: 0.35)
}
