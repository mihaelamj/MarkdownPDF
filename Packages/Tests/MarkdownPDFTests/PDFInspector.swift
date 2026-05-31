import Foundation

struct PDFInspector {
    struct Stream: Equatable {
        var declaredLength: Int
        var actualLength: Int
        var body: String
    }

    private let bytes: [UInt8]
    let text: String

    init(_ data: Data) {
        bytes = Array(data)
        text = String(decoding: data, as: UTF8.self)
    }

    var pageCount: Int {
        occurrences(of: "<< /Type /Page\n")
    }

    var linkAnnotationCount: Int {
        occurrences(of: "/Subtype /Link")
    }

    var streams: [Stream] {
        let streamMarker = Array("stream\n".utf8)
        let endMarker = Array("\nendstream".utf8)
        var result: [Stream] = []
        var searchStart = 0

        while let streamRange = range(of: streamMarker, from: searchStart),
              let endRange = range(of: endMarker, from: streamRange.upperBound)
        {
            let bodyBytes = bytes[streamRange.upperBound ..< endRange.lowerBound]
            result.append(
                Stream(
                    declaredLength: declaredLength(before: streamRange.lowerBound) ?? -1,
                    actualLength: bodyBytes.count,
                    body: String(decoding: bodyBytes, as: UTF8.self),
                ),
            )
            searchStart = endRange.upperBound
        }

        return result
    }

    func hasValidXrefOffsets() -> Bool {
        guard let entries = xrefEntries(), entries.contains(where: \.inUse) else {
            return false
        }

        for entry in entries where entry.inUse {
            guard hasBytes(Array("\(entry.objectNumber) 0 obj\n".utf8), at: entry.offset) else {
                return false
            }
        }

        return true
    }

    func streamLengthsMatch() -> Bool {
        let streams = streams
        return !streams.isEmpty && streams.allSatisfy { $0.declaredLength == $0.actualLength }
    }

    private func xrefEntries() -> [(objectNumber: Int, offset: Int, inUse: Bool)]? {
        let lines = text.components(separatedBy: "\n")
        guard let xrefIndex = lines.firstIndex(of: "xref"),
              xrefIndex + 2 < lines.count
        else {
            return nil
        }

        let header = lines[xrefIndex + 1].split(separator: " ")
        guard header.count == 2,
              let firstObject = Int(header[0]),
              let objectCount = Int(header[1])
        else {
            return nil
        }

        let firstEntryIndex = xrefIndex + 2
        guard firstEntryIndex + objectCount <= lines.count else {
            return nil
        }

        var entries: [(objectNumber: Int, offset: Int, inUse: Bool)] = []
        for relativeIndex in 0 ..< objectCount {
            let fields = lines[firstEntryIndex + relativeIndex].split(separator: " ")
            guard fields.count >= 3,
                  let offset = Int(fields[0])
            else {
                return nil
            }

            entries.append(
                (
                    objectNumber: firstObject + relativeIndex,
                    offset: offset,
                    inUse: fields[2] == "n"
                ),
            )
        }

        return entries
    }

    private func declaredLength(before byteIndex: Int) -> Int? {
        let prefix = String(decoding: bytes[..<byteIndex], as: UTF8.self)
        guard let lengthRange = prefix.range(of: "/Length ", options: .backwards) else {
            return nil
        }

        let digits = prefix[lengthRange.upperBound...].prefix(while: \.isNumber)
        return Int(digits)
    }

    private func occurrences(of needle: String) -> Int {
        var count = 0
        var searchRange = text.startIndex ..< text.endIndex

        while let match = text.range(of: needle, range: searchRange) {
            count += 1
            searchRange = match.upperBound ..< text.endIndex
        }

        return count
    }

    private func range(of needle: [UInt8], from start: Int) -> Range<Int>? {
        guard !needle.isEmpty, start <= bytes.count - needle.count else {
            return nil
        }

        var index = start
        while index <= bytes.count - needle.count {
            let candidate = bytes[index ..< index + needle.count]
            if candidate.elementsEqual(needle) {
                return index ..< index + needle.count
            }
            index += 1
        }

        return nil
    }

    private func hasBytes(_ expected: [UInt8], at offset: Int) -> Bool {
        guard offset >= 0, offset + expected.count <= bytes.count else {
            return false
        }

        return bytes[offset ..< offset + expected.count].elementsEqual(expected)
    }
}
