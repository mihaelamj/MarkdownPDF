import Foundation

enum StandardFont: String, CaseIterable {
    case helvetica = "F1"
    case helveticaBold = "F2"
    case helveticaOblique = "F3"
    case courier = "F4"

    func baseName(in fontSet: PDFOptions.FontSet) -> String {
        switch self {
        case .helvetica:
            fontSet.regular
        case .helveticaBold:
            fontSet.bold
        case .helveticaOblique:
            fontSet.italic
        case .courier:
            fontSet.monospaced
        }
    }

    func subtype(in fontSet: PDFOptions.FontSet) -> String {
        fontSet.subtype
    }

    var nominalWidth: Int {
        switch self {
        case .courier:
            600
        case .helveticaBold:
            560
        case .helveticaOblique:
            530
        case .helvetica:
            520
        }
    }

    var italicAngle: Int {
        switch self {
        case .helveticaOblique:
            -12
        default:
            0
        }
    }

    func width(of text: String, size: Double) -> Double {
        let factor = switch self {
        case .courier:
            0.6
        case .helveticaBold:
            0.56
        case .helveticaOblique:
            0.53
        case .helvetica:
            0.52
        }

        return Double(text.reduce(0) { count, character in
            count + (character.isWhitespace ? 1 : 1)
        }) * size * factor
    }
}
