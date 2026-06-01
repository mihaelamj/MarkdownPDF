struct PDFType0FontObject {
    var resourceName: String
    var baseName: String
    var descendantFont: PDFSyntax.Reference
    var toUnicodeMap: PDFSyntax.Reference

    var pdfDictionary: PDFSyntax.Dictionary {
        PDFSyntax.Dictionary([
            .init("Type", .pdfName("Font")),
            .init("Subtype", .pdfName("Type0")),
            .init("BaseFont", .pdfName(baseName)),
            .init("Encoding", .pdfName("Identity-H")),
            .init("DescendantFonts", .pdfArray([.reference(descendantFont)])),
            .init("ToUnicode", .reference(toUnicodeMap)),
        ])
    }
}
