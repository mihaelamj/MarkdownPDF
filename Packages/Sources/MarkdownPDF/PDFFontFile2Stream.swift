import Foundation

struct PDFFontFile2Stream {
    var fontProgram: Data

    var pdfStream: PDFSyntax.Stream {
        PDFSyntax.Stream(
            dictionary: PDFSyntax.Dictionary([
                .init("Length1", .int(fontProgram.count)),
            ]),
            data: fontProgram,
        )
    }
}
