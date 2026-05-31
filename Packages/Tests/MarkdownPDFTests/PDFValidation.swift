import Foundation

enum PDFValidation {
    struct Result {
        var exitCode: Int32
        var output: String
    }

    static func temporaryPDF(name: String, data: some DataProtocol) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownPDFValidation-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(name).pdf")
        try Data(data).write(to: url)
        return url
    }

    static func qpdfCheck(data: some DataProtocol, name: String) throws -> Result {
        let url = try temporaryPDF(name: name, data: data)
        return try qpdfCheck(url: url)
    }

    static func qpdfCheck(url: URL) throws -> Result {
        try Tool.run("qpdf", arguments: ["--check", url.path])
    }
}

private enum Tool {
    static func run(_ executable: String, arguments: [String]) throws -> PDFValidation.Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return PDFValidation.Result(
            exitCode: process.terminationStatus,
            output: String(decoding: output, as: UTF8.self),
        )
    }
}
