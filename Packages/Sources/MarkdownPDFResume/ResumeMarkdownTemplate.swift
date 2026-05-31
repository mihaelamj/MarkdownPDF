import Foundation

public struct ResumeMarkdownTemplate: Sendable {
    public var options: Options

    public init(options: Options = Options()) {
        self.options = options
    }

    public func markdown(for document: ResumeDocument) -> String {
        var writer = Writer(options: options)
        writer.render(document)
        return writer.output()
    }

    public struct Options: Equatable, Sendable {
        public var uppercaseSectionHeadings: Bool
        public var includeGeneratedNote: Bool

        public init(
            uppercaseSectionHeadings: Bool = true,
            includeGeneratedNote: Bool = false,
        ) {
            self.uppercaseSectionHeadings = uppercaseSectionHeadings
            self.includeGeneratedNote = includeGeneratedNote
        }
    }
}

private struct Writer {
    var options: ResumeMarkdownTemplate.Options
    var lines: [String] = []

    mutating func render(_ document: ResumeDocument) {
        heading(1, document.basics.name)
        if let headline = document.basics.headline.cleanValue {
            heading(2, headline)
        }
        contact(document.basics)
        paragraphs(document.summary)
        experience(document.experience)
        education(document.education)
        projects(document.projects)
        publications(document.publications)
        skills(document.skills)
        customSections(document.sections)

        if options.includeGeneratedNote {
            thematicBreak()
            line("*Generated from a structured resume template.*")
        }
    }

    func output() -> String {
        lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    mutating func contact(_ basics: ResumeDocument.Basics) {
        var parts: [String] = []
        if let email = basics.email.cleanValue {
            parts.append(link("Email", url: email.hasPrefix("mailto:") ? email : "mailto:\(email)"))
        }
        if let phone = basics.phone.cleanValue {
            parts.append(phone)
        }
        if let location = basics.location.cleanValue {
            parts.append(location)
        }
        parts.append(contentsOf: basics.links.map { link($0.label, url: $0.url) })

        guard !parts.isEmpty else {
            return
        }

        blank()
        line(parts.joined(separator: " | "))
    }

    mutating func paragraphs(_ values: [String]) {
        for value in values {
            guard let value = value.cleanValue else {
                continue
            }
            blank()
            line(value)
        }
    }

    mutating func experience(_ values: [ResumeDocument.Experience]) {
        guard !values.isEmpty else {
            return
        }

        section("Experience")
        for item in values {
            let title = [linkedTitle(item.organization, url: item.url), "(\(item.start) - \(item.end)), \(item.title)"].joined(separator: " ")
            heading(3, title)
            if let location = item.location.cleanValue {
                line(location)
            }
            paragraphs([item.summary].compactMap(\.self))
            list(item.highlights)
            nestedProjects(item.projects)
            technologies(item.technologies)
        }
    }

    mutating func education(_ values: [ResumeDocument.Education]) {
        guard !values.isEmpty else {
            return
        }

        section("Education")
        for item in values {
            var title = item.degree
            if let field = item.field.cleanValue {
                title += " in \(field)"
            }
            var subtitle = linkedTitle(item.institution, url: item.url)
            if let range = dateRange(start: item.start, end: item.end) {
                subtitle += " (\(range))"
            }
            heading(3, title)
            line(subtitle)
            list(item.details)
        }
    }

    mutating func projects(_ values: [ResumeDocument.Project]) {
        guard !values.isEmpty else {
            return
        }

        section("Projects")
        for item in values {
            project(item, level: 3)
        }
    }

    mutating func publications(_ values: [ResumeDocument.Publication]) {
        guard !values.isEmpty else {
            return
        }

        section("Publications")
        for item in values {
            var title = linkedTitle(item.title, url: item.url)
            let metadata = [item.venue.cleanValue, item.date.cleanValue].compactMap(\.self).joined(separator: ", ")
            if !metadata.isEmpty {
                title += " (\(metadata))"
            }
            heading(3, title)
            list(item.details)
        }
    }

    mutating func skills(_ values: [ResumeDocument.SkillGroup]) {
        let nonEmptyValues = values.filter { !$0.items.isEmpty }
        guard !nonEmptyValues.isEmpty else {
            return
        }

        section("Skills")
        var wroteGroup = false
        for group in nonEmptyValues {
            if wroteGroup {
                blank()
            }
            line("**\(group.name):** \(group.items.joined(separator: ", "))")
            wroteGroup = true
        }
    }

    mutating func customSections(_ values: [ResumeDocument.Section]) {
        for sectionValue in values {
            guard !sectionValue.entries.isEmpty else {
                continue
            }
            section(sectionValue.title)
            for entry in sectionValue.entries {
                var title = linkedTitle(entry.title, url: entry.url)
                if let subtitle = entry.subtitle.cleanValue {
                    title += " (\(subtitle))"
                }
                heading(3, title)
                list(entry.details)
                technologies(entry.technologies)
            }
        }
    }

    mutating func nestedProjects(_ values: [ResumeDocument.Project]) {
        for item in values {
            project(item, level: 4)
        }
    }

    mutating func project(_ item: ResumeDocument.Project, level: Int) {
        var title = linkedTitle(item.name, url: item.url)
        if let role = item.role.cleanValue {
            title += ", \(role)"
        }
        heading(level, title)
        paragraphs([item.summary].compactMap(\.self))
        list(item.highlights)
        technologies(item.technologies)
    }

    mutating func technologies(_ values: [String]) {
        guard !values.isEmpty else {
            return
        }
        blank()
        line("**Technologies:** \(values.joined(separator: ", "))")
    }

    mutating func list(_ values: [String]) {
        for value in values {
            guard let value = value.cleanValue else {
                continue
            }
            line("- \(value)")
        }
    }

    mutating func section(_ title: String) {
        heading(2, options.uppercaseSectionHeadings ? title.uppercased() : title)
    }

    mutating func heading(_ level: Int, _ text: String) {
        blank()
        line(String(repeating: "#", count: level) + " " + text)
    }

    mutating func thematicBreak() {
        blank()
        line("---")
    }

    mutating func blank() {
        if lines.last?.isEmpty == false {
            lines.append("")
        }
    }

    mutating func line(_ value: String) {
        lines.append(value)
    }

    func linkedTitle(_ title: String, url: String?) -> String {
        guard let url = url.cleanValue else {
            return title
        }
        return link(title, url: url)
    }

    func link(_ label: String, url: String) -> String {
        "[\(label)](\(url))"
    }

    func dateRange(start: String?, end: String?) -> String? {
        let values = [start.cleanValue, end.cleanValue].compactMap(\.self)
        guard !values.isEmpty else {
            return nil
        }
        return values.joined(separator: " - ")
    }
}

private extension String? {
    var cleanValue: String? {
        switch self {
        case let .some(value):
            value.cleanValue
        case .none:
            nil
        }
    }
}

private extension String {
    var cleanValue: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
