import Foundation
import MarkdownPDF
import MarkdownPDFResume
import Testing

@Suite("Resume Markdown template")
struct ResumeMarkdownTemplateTests {
    @Test("Renders structured resume Markdown")
    func rendersStructuredResumeMarkdown() throws {
        let resume = try demoResume()
        let markdown = ResumeMarkdownTemplate().markdown(for: resume)

        #expect(markdown.contains("# Alex Rivera"))
        #expect(markdown.contains("## EXPERIENCE"))
        #expect(markdown.contains("### [Northbridge Systems](https://example.com/northbridge) (Sep 2025 - Present), Senior Mobile Architect"))
        #expect(markdown.contains("#### Identity Capture Platform"))
        #expect(markdown.contains("**Technologies:** Swift, SwiftUI, UIKit, Swift Package Manager, Unit Testing"))
        #expect(markdown.contains("## SKILLS"))
        #expect(markdown.contains("**Languages:** Swift, Objective-C\n\n**Frameworks:** SwiftUI, UIKit, AppKit"))
    }

    @Test("Generated resume Markdown renders through generic PDF renderer")
    func generatedResumeMarkdownRendersThroughGenericRenderer() throws {
        let resume = try demoResume()
        let markdown = ResumeMarkdownTemplate().markdown(for: resume)
        let data = try MarkdownPDFRenderer().render(markdown: markdown)
        let text = String(decoding: data, as: UTF8.self)

        #expect(text.hasPrefix("%PDF-1.4"))
        #expect(text.contains("/Subtype /Link"))
        #expect(text.contains("/URI (https://example.com/northbridge)"))
    }

    @Test("Decodes omitted arrays as empty values")
    func decodesOmittedArraysAsEmptyValues() throws {
        let json = """
        {
          "basics": {
            "name": "Alex Rivera"
          },
          "skills": [
            {
              "name": "Languages"
            }
          ]
        }
        """
        let resume = try JSONDecoder().decode(
            ResumeDocument.self,
            from: Data(json.utf8),
        )

        #expect(resume.summary.isEmpty)
        #expect(resume.experience.isEmpty)
        #expect(resume.basics.links.isEmpty)
        #expect(resume.skills == [ResumeDocument.SkillGroup(name: "Languages", items: [])])
        #expect(ResumeMarkdownTemplate().markdown(for: resume).contains("## SKILLS") == false)
    }

    private func demoResume() throws -> ResumeDocument {
        let testFile = URL(fileURLWithPath: #filePath)
        let fixtureURL = testFile
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/democv.json")
        let data = try Data(contentsOf: fixtureURL)
        return try JSONDecoder().decode(ResumeDocument.self, from: data)
    }
}
