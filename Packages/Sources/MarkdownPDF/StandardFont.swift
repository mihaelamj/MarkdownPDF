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

    var italicAngle: Int {
        switch self {
        case .helveticaOblique:
            -12
        default:
            0
        }
    }

    func width(
        of text: String,
        size: Double,
        fontSet: PDFOptions.FontSet,
    ) -> Double {
        let widths = widthTable(in: fontSet)

        let units = text.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + widths.width(for: scalar)
        }
        return Double(units) * size / 1000
    }

    func widthsForPDF(in fontSet: PDFOptions.FontSet) -> [Int] {
        let widths = widthTable(in: fontSet)
        return (32 ... 126).compactMap(UnicodeScalar.init).map {
            widths.width(for: $0)
        }
    }

    private func widthTable(in fontSet: PDFOptions.FontSet) -> WidthTable {
        let baseName = baseName(in: fontSet)
        if self == .courier || baseName.hasPrefix("Courier") || baseName.hasPrefix("SFMono") {
            return FontWidths.courier
        }
        if self == .helveticaBold {
            return FontWidths.helveticaBold
        }
        return FontWidths.helvetica
    }
}

private enum FontWidths {
    static let courier = WidthTable(defaultWidth: 600, widths: [:])

    static let helvetica = WidthTable(defaultWidth: 556, widths: [
        " ": 278, "!": 278, "\"": 355, "#": 556, "$": 556, "%": 889, "&": 667, "'": 222,
        "(": 333, ")": 333, "*": 389, "+": 584, ",": 278, "-": 333, ".": 278, "/": 278,
        "0": 556, "1": 556, "2": 556, "3": 556, "4": 556, "5": 556, "6": 556, "7": 556,
        "8": 556, "9": 556, ":": 278, ";": 278, "<": 584, "=": 584, ">": 584, "?": 556,
        "@": 1015, "A": 667, "B": 667, "C": 722, "D": 722, "E": 667, "F": 611, "G": 778,
        "H": 722, "I": 278, "J": 500, "K": 667, "L": 556, "M": 833, "N": 722, "O": 778,
        "P": 667, "Q": 778, "R": 722, "S": 667, "T": 611, "U": 722, "V": 667, "W": 944,
        "X": 667, "Y": 667, "Z": 611, "[": 278, "\\": 278, "]": 278, "^": 469, "_": 556,
        "`": 222, "a": 556, "b": 556, "c": 500, "d": 556, "e": 556, "f": 278, "g": 556,
        "h": 556, "i": 222, "j": 222, "k": 500, "l": 222, "m": 833, "n": 556, "o": 556,
        "p": 556, "q": 556, "r": 333, "s": 500, "t": 278, "u": 556, "v": 500, "w": 722,
        "x": 500, "y": 500, "z": 500, "{": 334, "|": 260, "}": 334, "~": 584,
    ])

    static let helveticaBold = WidthTable(defaultWidth: 556, widths: [
        " ": 278, "!": 333, "\"": 474, "#": 556, "$": 556, "%": 889, "&": 722, "'": 278,
        "(": 333, ")": 333, "*": 389, "+": 584, ",": 278, "-": 333, ".": 278, "/": 278,
        "0": 556, "1": 556, "2": 556, "3": 556, "4": 556, "5": 556, "6": 556, "7": 556,
        "8": 556, "9": 556, ":": 333, ";": 333, "<": 584, "=": 584, ">": 584, "?": 611,
        "@": 975, "A": 722, "B": 722, "C": 722, "D": 722, "E": 667, "F": 611, "G": 778,
        "H": 722, "I": 278, "J": 556, "K": 722, "L": 611, "M": 833, "N": 722, "O": 778,
        "P": 667, "Q": 778, "R": 722, "S": 667, "T": 611, "U": 722, "V": 667, "W": 944,
        "X": 667, "Y": 667, "Z": 611, "[": 333, "\\": 278, "]": 333, "^": 584, "_": 556,
        "`": 278, "a": 556, "b": 611, "c": 556, "d": 611, "e": 556, "f": 333, "g": 611,
        "h": 611, "i": 278, "j": 278, "k": 556, "l": 278, "m": 889, "n": 611, "o": 611,
        "p": 611, "q": 611, "r": 389, "s": 556, "t": 333, "u": 611, "v": 556, "w": 778,
        "x": 556, "y": 556, "z": 500, "{": 389, "|": 280, "}": 389, "~": 584,
    ])
}

private struct WidthTable {
    var defaultWidth: Int
    var widths: [UnicodeScalar: Int]

    func width(for scalar: UnicodeScalar) -> Int {
        if let width = widths[scalar] {
            return width
        }

        return widths["?"] ?? defaultWidth
    }
}
