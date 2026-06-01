struct PDFCIDFontWidths: Equatable {
    enum Segment: Equatable {
        case array(startCID: Int, widths: [Int])
        case range(startCID: Int, endCID: Int, width: Int)
    }

    var segments: [Segment]

    init(segments: [Segment]) {
        precondition(!segments.isEmpty, "CID font widths require at least one segment")
        for segment in segments {
            switch segment {
            case let .array(_, widths):
                precondition(!widths.isEmpty, "CID font array width segments cannot be empty")
            case let .range(startCID, endCID, _):
                precondition(startCID <= endCID, "CID font range width segments must be ordered")
            }
        }
        self.segments = segments
    }

    var pdfValue: PDFSyntax.Value {
        .pdfArray(segments.flatMap(\.pdfValues))
    }
}

private extension PDFCIDFontWidths.Segment {
    var pdfValues: [PDFSyntax.Value] {
        switch self {
        case let .array(startCID, widths):
            [
                .int(startCID),
                .pdfArray(widths.map { .int($0) }),
            ]
        case let .range(startCID, endCID, width):
            [
                .int(startCID),
                .int(endCID),
                .int(width),
            ]
        }
    }
}
