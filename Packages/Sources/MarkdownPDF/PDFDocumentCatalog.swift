struct PDFDocumentCatalog {
    var pages: PDFSyntax.Reference
    var outlines: PDFSyntax.Reference?
    var names: PDFSyntax.Dictionary?
    var metadata: PDFSyntax.Reference?
    var displayDocumentTitle: Bool

    var pdfDictionary: PDFSyntax.Dictionary {
        var entries: [PDFSyntax.Dictionary.Entry] = [
            .init("Type", .pdfName("Catalog")),
            .init("Pages", .reference(pages)),
        ]
        if let outlines {
            entries.append(.init("Outlines", .reference(outlines)))
            entries.append(.init("PageMode", .pdfName("UseOutlines")))
        }
        if let names {
            entries.append(.init("Names", .dictionary(names)))
        }
        if let metadata {
            entries.append(.init("Metadata", .reference(metadata)))
        }
        if displayDocumentTitle {
            entries.append(
                .init(
                    "ViewerPreferences",
                    .pdfDictionary([
                        .init("DisplayDocTitle", .bool(true)),
                    ]),
                ),
            )
        }
        return PDFSyntax.Dictionary(entries)
    }
}
