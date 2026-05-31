import Foundation

final class PDFPageCanvas {
    private(set) var commands: String = ""

    func drawTextRun(
        _ run: PDFTextRun,
        x: Double,
        y: Double,
    ) {
        setFillColor(run.color)
        append("BT /\(run.font.rawValue) \(format(run.size)) Tf \(format(x)) \(format(y)) Td \(run.text.pdfLiteralString) Tj ET\n")

        let width = run.width()
        if run.underline {
            drawLine(
                x1: x,
                y1: y - 1.5,
                x2: x + width,
                y2: y - 1.5,
                width: 0.5,
                color: run.color,
            )
        }
        if run.strikethrough {
            drawLine(
                x1: x,
                y1: y + run.size * 0.32,
                x2: x + width,
                y2: y + run.size * 0.32,
                width: 0.5,
                color: run.color,
            )
        }
    }

    func drawLine(
        x1: Double,
        y1: Double,
        x2: Double,
        y2: Double,
        width: Double,
        color: PDFColor = .black,
    ) {
        setStrokeColor(color)
        append("\(format(width)) w \(format(x1)) \(format(y1)) m \(format(x2)) \(format(y2)) l S\n")
    }

    func drawRectangle(
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        stroke: PDFColor? = .black,
        fill: PDFColor? = nil,
    ) {
        if let fill {
            setFillColor(fill)
            append("\(format(x)) \(format(y)) \(format(width)) \(format(height)) re f\n")
        }
        if let stroke {
            setStrokeColor(stroke)
            append("0.5 w \(format(x)) \(format(y)) \(format(width)) \(format(height)) re S\n")
        }
    }

    func drawImage(
        name: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
    ) {
        append("q \(format(width)) 0 0 \(format(height)) \(format(x)) \(format(y)) cm /\(name) Do Q\n")
    }

    private func setFillColor(_ color: PDFColor) {
        append("\(format(color.red)) \(format(color.green)) \(format(color.blue)) rg\n")
    }

    private func setStrokeColor(_ color: PDFColor) {
        append("\(format(color.red)) \(format(color.green)) \(format(color.blue)) RG\n")
    }

    private func append(_ command: String) {
        commands.append(command)
    }
}

private extension String {
    var pdfLiteralString: String {
        var output = "("
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x08:
                output += "\\b"
            case 0x09:
                output += "\\t"
            case 0x0A:
                output += "\\n"
            case 0x0C:
                output += "\\f"
            case 0x0D:
                output += "\\r"
            case 0x28:
                output += "\\("
            case 0x29:
                output += "\\)"
            case 0x5C:
                output += "\\\\"
            case 32 ... 126:
                output.append(Character(scalar))
            case 160 ... 255:
                output += String(format: "\\%03o", scalar.value)
            default:
                output += "?"
            }
        }
        output += ")"
        return output
    }
}

func format(_ value: Double) -> String {
    let rounded = (value * 1000).rounded() / 1000
    return String(format: "%.3f", rounded)
        .replacingOccurrences(of: ".000", with: "")
}
