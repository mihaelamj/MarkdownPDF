import Foundation
import MarkdownPDF
import Testing

#if canImport(MarkdownPDFMac)
    import MarkdownPDFMac
#endif

@Suite("Fixtures")
struct FixtureTests {
    @Test("Public fixtures are anonymized")
    func publicFixturesAreAnonymized() throws {
        let forbiddenIdentifiers = [
            "Mihaela",
            "Mihaljevic",
            "Mihaljević",
            "Jakic",
            "Jakić",
            "mihaelamj",
            "aleahim",
            "diyamantina",
            "+385",
            "Zagreb",
            "Croatia",
            "Maurer",
            "Bundesdruckerei",
            "Code Weaver",
            "Everliv",
            "iOLAP",
            "iRobot",
            "Zumiez",
            "Cherishing",
            "Budtz",
            "Birch",
            "Wheels Up",
            "Masinerija",
            "Purch",
            "Undabot",
            "Cupertino",
            "iRelay",
            "OpenAPIDoctor",
            "ExtremePackaging",
            "OpenAPILoggingMiddleware",
            "CVBuilder",
            "iOSKonf",
            "NSSpain",
            "Skopje",
            "Logrono",
            "Logroño",
        ]

        for fixtureName in publicFixtureNames {
            let fixture = try fixture(named: fixtureName)
            for identifier in forbiddenIdentifiers {
                #expect(!fixture.localizedCaseInsensitiveContains(identifier))
            }
        }
    }

    @Test("Renders demo CV fixture")
    func rendersDemoCVFixture() throws {
        let fixture = try demoCVFixture()
        let data = try MarkdownPDFRenderer().render(markdown: fixture)
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.hasPrefix("%PDF-1.4"))
        #expect(text.contains("/BaseFont /Helvetica"))
        #expect(text.contains("/Type /Page"))
        #expect(text.contains("xref"))
    }

    @Test("Renders article-grade fixtures with valid PDF structure")
    func rendersArticleGradeFixtures() throws {
        for fixtureName in articleGradeFixtureNames {
            let data = try MarkdownPDFRenderer().render(markdown: fixture(named: fixtureName))
            let inspector = PDFInspector(data)

            #expect(inspector.text.hasPrefix("%PDF-1.4"))
            #expect(inspector.text.contains("/BaseFont /Helvetica"))
            #expect(!inspector.text.contains("/FontFile"))
            #expect(inspector.pageCount >= 1)
            #expect(inspector.hasValidXrefOffsets())
            #expect(inspector.streamLengthsMatch())

            let qpdf = try PDFValidation.qpdfCheck(data: data, name: fixtureName)
            #expect(qpdf.exitCode == 0, "qpdf --check failed for \(fixtureName):\n\(qpdf.output)")

            let infoResult = try PDFValidation.pdfinfo(data: data, name: fixtureName)
            let info = PDFValidation.parsedInfo(from: infoResult)
            #expect(infoResult.exitCode == 0, "pdfinfo failed for \(fixtureName):\n\(infoResult.output)")
            #expect(info["PDF version"] == "1.4", "Unexpected pdfinfo output for \(fixtureName):\n\(infoResult.output)")
            #expect(info["Pages"] == "\(inspector.pageCount)", "Unexpected pdfinfo output for \(fixtureName):\n\(infoResult.output)")

            let textResult = try PDFValidation.pdftotext(data: data, name: fixtureName)
            #expect(textResult.exitCode == 0, "pdftotext failed for \(fixtureName):\n\(textResult.output)")
            #expect(
                textResult.output.contains(expectedTextFragment(for: fixtureName)),
                "Unexpected pdftotext output for \(fixtureName):\n\(textResult.output)",
            )

            let render = try PDFValidation.pdftoppmPNG(data: data, name: fixtureName)
            let pngData = try? Data(contentsOf: render.pngURL)
            let dimensions = PDFValidation.pngDimensions(in: pngData)
            #expect(render.result.exitCode == 0, "pdftoppm failed for \(fixtureName):\n\(render.result.output)")
            #expect(dimensions != nil)
            #expect((dimensions?.width ?? 0) > 0)
            #expect((dimensions?.height ?? 0) > 0)
        }
    }

    @Test("Scientific article fixture covers links and image fallback")
    func scientificArticleFixtureCoversLinksAndImageFallback() throws {
        let data = try MarkdownPDFRenderer().render(markdown: fixture(named: "scientific-article.md"))
        let inspector = PDFInspector(data)
        let streamText = inspector.streams.map(\.body).joined(separator: "\n")

        #expect(inspector.linkAnnotationCount >= 1)
        #expect(inspector.text.contains("/URI (https://example.com/research/layout-measurements)"))
        #expect(streamText.contains("([Remote )"))
        #expect(streamText.contains("(image: )"))
        #expect(streamText.contains("(flowchart TD)"))
    }

    #if canImport(MarkdownPDFMac)
        @Test("Mac product renders scientific article fixture")
        func macProductRendersScientificArticleFixture() throws {
            let data = try MarkdownPDFMacRenderer().render(markdown: fixture(named: "scientific-article.md"))
            let inspector = PDFInspector(data)

            #expect(inspector.text.hasPrefix("%PDF-1.4"))
            #expect(!inspector.text.contains("/FontFile"))
            #expect(inspector.hasValidXrefOffsets())
            #expect(inspector.streamLengthsMatch())
        }
    #endif

    private func demoCVFixture() throws -> String {
        try fixture(named: "democv.md")
    }

    private func fixture(named name: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let fixtureURL = testFile
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name)")
        return try String(contentsOf: fixtureURL, encoding: .utf8)
    }

    private var publicFixtureNames: [String] {
        ["democv.md"] + articleGradeFixtureNames
    }

    private var articleGradeFixtureNames: [String] {
        [
            "scientific-article.md",
            "technical-report.md",
        ]
    }

    private func expectedTextFragment(for fixtureName: String) -> String {
        switch fixtureName {
        case "scientific-article.md":
            "Reproducible Layout Measurements"
        case "technical-report.md":
            "Portable PDF Validation Technical Report"
        default:
            fixtureName
        }
    }
}
