import Foundation

struct PDFFontFile2Stream {
    var fontProgram: Data

    init(fontProgram: Data) {
        precondition(!fontProgram.isEmpty, "FontFile2 streams require a font program")
        self.fontProgram = fontProgram
    }

    var pdfStream: PDFSyntax.Stream {
        PDFSyntax.Stream(
            dictionary: PDFSyntax.Dictionary([
                .init("Length1", .int(fontProgram.count)),
            ]),
            data: fontProgram,
        )
    }
}
