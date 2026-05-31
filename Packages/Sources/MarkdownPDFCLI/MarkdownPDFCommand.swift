import Foundation
import MarkdownPDF

@main
struct MarkdownPDFCommand {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.count == 2 else {
            print("Usage: markdownpdf input.md output.pdf")
            throw CLIError.invalidArguments
        }

        let inputURL = URL(fileURLWithPath: arguments[0])
        let outputURL = URL(fileURLWithPath: arguments[1])
        let markdown = try String(contentsOf: inputURL, encoding: .utf8)
        let renderer = MarkdownPDFRenderer(
            options: PDFOptions(title: inputURL.deletingPathExtension().lastPathComponent),
        )
        let data = try renderer.render(
            markdown: markdown,
            assetsBaseURL: inputURL.deletingLastPathComponent(),
        )
        try data.write(to: outputURL)
    }
}

private enum CLIError: Error {
    case invalidArguments
}
