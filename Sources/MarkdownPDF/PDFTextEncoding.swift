enum PDFTextEncoding {
    static func portableText(for text: String) -> String {
        String(String.UnicodeScalarView(portableScalars(for: text)))
    }

    static func portableScalars(for text: String) -> [UnicodeScalar] {
        text.unicodeScalars.map { portableScalar(for: $0) }
    }

    static func encodedByte(for scalar: UnicodeScalar) -> UInt8 {
        UInt8(portableScalar(for: scalar).value)
    }

    static func portableScalar(for scalar: UnicodeScalar) -> UnicodeScalar {
        if isPortableScalar(scalar) {
            return scalar
        }

        return replacementScalar
    }

    static func isPortableScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x08, 0x09, 0x0A, 0x0C, 0x0D, 0x20 ... 0x7E:
            true
        default:
            false
        }
    }

    static let replacementScalar: UnicodeScalar = "?"
}
