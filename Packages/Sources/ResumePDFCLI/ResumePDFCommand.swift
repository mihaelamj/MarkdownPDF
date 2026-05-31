import Foundation
import MarkdownPDF
import MarkdownPDFResume

@main
struct ResumePDFCommand {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.count == 2 else {
            print("Usage: resumepdf input.json output.pdf")
            throw CLIError.invalidArguments
        }

        let inputURL = URL(fileURLWithPath: arguments[0])
        let outputURL = URL(fileURLWithPath: arguments[1])
        let data = try Data(contentsOf: inputURL)
        let resume = try JSONDecoder().decode(ResumeDocument.self, from: data)
        let markdown = ResumeMarkdownTemplate().markdown(for: resume)
        let renderer = MarkdownPDFRenderer(
            options: PDFOptions(title: resume.basics.name),
        )
        let pdf = try renderer.render(
            markdown: markdown,
            assetsBaseURL: inputURL.deletingLastPathComponent(),
        )
        try pdf.write(to: outputURL)
    }
}

private enum CLIError: Error {
    case invalidArguments
}
