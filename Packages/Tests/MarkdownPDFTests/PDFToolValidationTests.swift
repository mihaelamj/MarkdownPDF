import Foundation
import MarkdownPDF
import Testing

@Suite("PDF tool validation")
struct PDFToolValidationTests {
    @Test("qpdf validates minimal PDF structure")
    func qpdfValidatesMinimalPDFStructure() throws {
        let result = try PDFValidation.qpdfCheck(
            data: MarkdownPDFRenderer().render(markdown: "Hello from MarkdownPDF."),
            name: "minimal-valid",
        )

        #expect(result.exitCode == 0, "qpdf --check failed:\n\(result.output)")
    }

    @Test("qpdf reports damaged PDF structure")
    func qpdfReportsDamagedPDFStructure() throws {
        let data = try MarkdownPDFRenderer().render(markdown: "Hello from MarkdownPDF.")
        let result = try PDFValidation.qpdfCheck(
            data: data.prefix(data.count / 2),
            name: "minimal-truncated",
        )

        #expect(result.exitCode == 2 || result.exitCode == 3, "qpdf unexpectedly accepted damaged PDF:\n\(result.output)")
        #expect(result.output.contains("WARNING") || result.output.contains("ERROR") || result.output.contains("qpdf:"))
    }
}
