import Foundation
import MarkdownPDF
import Testing

@Suite("Fixtures")
struct FixtureTests {
    @Test("Demo CV fixture is anonymized")
    func demoCVFixtureIsAnonymized() throws {
        let fixture = try demoCVFixture()
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

        for identifier in forbiddenIdentifiers {
            #expect(!fixture.localizedCaseInsensitiveContains(identifier))
        }
    }

    @Test("Renders demo CV fixture")
    func rendersDemoCVFixture() throws {
        let fixture = try demoCVFixture()
        let data = try MarkdownPDFRenderer().render(markdown: fixture)
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.hasPrefix("%PDF-1.4"))
        #expect(text.contains("/BaseFont /Courier"))
        #expect(text.contains("/Type /Page"))
        #expect(text.contains("xref"))
    }

    private func demoCVFixture() throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let fixtureURL = testFile
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/democv.md")
        return try String(contentsOf: fixtureURL, encoding: .utf8)
    }
}
