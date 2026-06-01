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
            let data = try renderArticleFixture(named: fixtureName)
            let inspector = PDFInspector(data)

            #expect(inspector.text.hasPrefix("%PDF-1.4"))
            #expect(inspector.text.contains("/BaseFont /Helvetica"))
            #expect(!inspector.text.contains("/FontFile"))
            #expect(inspector.pageCount >= expectedMinimumPageCount(for: fixtureName))
            #expect(inspector.hasValidXrefOffsets())
            #expect(inspector.streamLengthsMatch())
            #expect(
                inspector.canonicalStructureIssues().isEmpty,
                "Canonical PDF structure failed for \(fixtureName):\n\(inspector.canonicalStructureReport())",
            )

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

    @Test("Article stress fixture covers ToC, images, fallback, raw HTML, and Mermaid")
    func articleStressFixtureCoversPortableArticleFeatures() throws {
        let data = try renderArticleFixture(named: "article-grade-stress.md")
        let inspector = PDFInspector(data)
        let textResult = try PDFValidation.pdftotext(data: data, name: "article-grade-stress-features")
        try #require(textResult.exitCode == 0, "pdftotext failed for article-grade stress fixture:\n\(textResult.output)")
        let extractedText = textResult.output

        #expect(inspector.pageCount >= 6)
        #expect(inspector.linkAnnotationCount >= 2)
        #expect(inspector.text.contains("/Names << /Dests"))
        #expect(inspector.text.contains("/Subtype /Image"))
        #expect(inspector.text.contains("/Width 96"))
        #expect(inspector.text.contains("/Height 48"))
        #expect(inspector.text.contains("/FlateDecode"))
        #expect(extractedText.contains("Table of Contents"))
        #expect(extractedText.contains("[Remote image: Remote measurement plot]"))
        #expect(extractedText.contains("Raw HTML fallback"))
        #expect(extractedText.contains("Markdown source"))
        #expect(extractedText.contains("Open tool witnesses"))
        #expect(!extractedText.contains("Unsupported Mermaid diagram"))
        #expect(!extractedText.contains("flowchart TD"))
    }

    @Test("Hard Markdown fixture covers dense portable Markdown features")
    func hardMarkdownFixtureCoversDensePortableMarkdownFeatures() throws {
        let data = try renderArticleFixture(named: "hard-markdown-corpus.md")
        let inspector = PDFInspector(data)
        let textResult = try PDFValidation.pdftotext(data: data, name: "hard-markdown-corpus-features")
        try #require(textResult.exitCode == 0, "pdftotext failed for hard Markdown fixture:\n\(textResult.output)")
        let extractedText = textResult.output
        let normalizedText = normalizedExtractedText(extractedText)

        #expect(inspector.pageCount >= 8)
        #expect(inspector.linkAnnotationCount >= 4)
        #expect(inspector.text.contains("/Names << /Dests"))
        #expect(inspector.text.contains("/Subtype /Image"))
        #expect(inspector.text.contains("/Width 96"))
        #expect(inspector.text.contains("/Height 48"))
        #expect(inspector.text.contains("/FlateDecode"))
        #expect(extractedText.contains("Table of Contents"))
        #expect(normalizedText.contains("Portable Hard Markdown Corpus"))
        #expect(normalizedText.contains("Raw HTML fallback for the hard corpus"))
        #expect(extractedText.contains("[Remote image: Remote hard corpus figure]"))
        #expect(normalizedText.contains("Hard input"))
        #expect(normalizedText.contains("Open tools"))
        #expect(extractedText.contains("Unsupported Mermaid diagram"))
        #expect(extractedText.contains("Unsupported hard corpus chart"))
        #expect(normalizedText.contains("Hard Fixture Exit Marker"))
        #expect(!extractedText.contains("Source[Hard input]"))
    }

    @Test("Scientific article fixture covers links, image fallback, and Mermaid")
    func scientificArticleFixtureCoversLinksImageFallbackAndMermaid() throws {
        let data = try MarkdownPDFRenderer().render(markdown: fixture(named: "scientific-article.md"))
        let inspector = PDFInspector(data)
        let streamText = inspector.streams.map(\.body).joined(separator: "\n")

        #expect(inspector.linkAnnotationCount >= 1)
        #expect(inspector.text.contains("/URI (https://example.com/research/layout-measurements)"))
        #expect(streamText.contains("([Remote )"))
        #expect(streamText.contains("(image: )"))
        #expect(streamText.contains("(Markdown )"))
        #expect(streamText.contains("(source)"))
        #expect(streamText.contains("(PDF )"))
        #expect(streamText.contains("(bytes)"))
        #expect(!streamText.contains("(flowchart TD)"))
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

    private func renderArticleFixture(named fixtureName: String) throws -> Data {
        try MarkdownPDFRenderer(options: articleFixtureOptions(for: fixtureName)).render(
            markdown: fixture(named: fixtureName),
            assetsBaseURL: articleFixtureAssetsBaseURL(for: fixtureName),
        )
    }

    private func articleFixtureOptions(for fixtureName: String) -> PDFOptions {
        if ["article-grade-stress.md", "hard-markdown-corpus.md"].contains(fixtureName) {
            return PDFOptions(
                pageSize: PDFOptions.PageSize(width: 260, height: 320),
                margins: PDFOptions.Margins(top: 24, right: 22, bottom: 24, left: 22),
                baseFontSize: 10,
                title: expectedTextFragment(for: fixtureName),
                tableOfContents: .enabled,
            )
        }

        return PDFOptions()
    }

    private func articleFixtureAssetsBaseURL(for fixtureName: String) throws -> URL? {
        if ["article-grade-stress.md", "hard-markdown-corpus.md"].contains(fixtureName) {
            return try TestImageAssets.directoryWithChartPNG()
        }

        return nil
    }

    private var publicFixtureNames: [String] {
        ["democv.md"] + articleGradeFixtureNames
    }

    private var articleGradeFixtureNames: [String] {
        [
            "article-grade-stress.md",
            "hard-markdown-corpus.md",
            "scientific-article.md",
            "technical-report.md",
        ]
    }

    private func expectedTextFragment(for fixtureName: String) -> String {
        switch fixtureName {
        case "article-grade-stress.md":
            "Portable Article Stress Corpus"
        case "hard-markdown-corpus.md":
            "Portable Hard Markdown Corpus"
        case "scientific-article.md":
            "Reproducible Layout Measurements"
        case "technical-report.md":
            "Portable PDF Validation Technical Report"
        default:
            fixtureName
        }
    }

    private func expectedMinimumPageCount(for fixtureName: String) -> Int {
        switch fixtureName {
        case "article-grade-stress.md", "hard-markdown-corpus.md":
            6
        default:
            1
        }
    }

    private func normalizedExtractedText(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
