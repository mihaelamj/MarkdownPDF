import Foundation

struct PDFToUnicodeCMap {
    struct Mapping: Equatable {
        var code: UInt16
        var unicode: String
    }

    var name: String
    var mappings: [Mapping]

    init(name: String = "MarkdownPDF-ToUnicode", mappings: [Mapping]) {
        precondition(!mappings.isEmpty, "ToUnicode CMaps require at least one mapping")
        precondition(
            Set(mappings.map(\.code)).count == mappings.count,
            "ToUnicode CMap codes must be unique",
        )
        precondition(
            mappings.allSatisfy { !$0.unicode.isEmpty },
            "ToUnicode CMap mappings require a Unicode scalar sequence",
        )
        self.name = name
        self.mappings = mappings.sorted { lhs, rhs in
            lhs.code < rhs.code
        }
    }

    var pdfStream: PDFSyntax.Stream {
        PDFSyntax.Stream(dictionary: PDFSyntax.Dictionary(), data: data)
    }

    var data: Data {
        Data(serialized.utf8)
    }

    var serialized: String {
        var lines = [
            "/CIDInit /ProcSet findresource begin",
            "12 dict begin",
            "begincmap",
            "/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def",
            "/CMapName \(PDFSyntax.Name(name).serialized) def",
            "/CMapType 2 def",
            "1 begincodespacerange",
            "<0000> <FFFF>",
            "endcodespacerange",
        ]

        for chunk in mappingChunks {
            lines.append("\(chunk.count) beginbfchar")
            lines.append(contentsOf: chunk.map { mapping in
                "\(Self.hex(mapping.code)) \(Self.hex(mapping.unicode))"
            })
            lines.append("endbfchar")
        }

        lines.append(contentsOf: [
            "endcmap",
            "CMapName currentdict /CMap defineresource pop",
            "end",
            "end",
            "",
        ])

        return lines.joined(separator: "\n")
    }

    private var mappingChunks: [[Mapping]] {
        stride(from: 0, to: mappings.count, by: 100).map { start in
            Array(mappings[start ..< Swift.min(start + 100, mappings.count)])
        }
    }

    private static func hex(_ code: UInt16) -> String {
        String(format: "<%04X>", locale: serializationLocale, code)
    }

    private static func hex(_ string: String) -> String {
        let body = string.utf16.map { unit in
            String(format: "%04X", locale: serializationLocale, unit)
        }.joined()
        return "<\(body)>"
    }

    private static let serializationLocale = Locale(identifier: "en_US_POSIX")
}
