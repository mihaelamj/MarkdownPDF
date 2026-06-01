struct PDFCIDSystemInfo: Equatable {
    var registry: String
    var ordering: String
    var supplement: Int

    static let identity = PDFCIDSystemInfo(
        registry: "Adobe",
        ordering: "Identity",
        supplement: 0,
    )

    var pdfDictionary: PDFSyntax.Dictionary {
        PDFSyntax.Dictionary([
            .init("Registry", .pdfString(registry)),
            .init("Ordering", .pdfString(ordering)),
            .init("Supplement", .int(supplement)),
        ])
    }
}
