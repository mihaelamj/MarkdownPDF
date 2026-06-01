import Foundation

struct PDFEmbeddedFontCatalog {
    struct Entry {
        var resource: PDFEmbeddedFontResource
        var mapper: TrueTypeGlyphMapper
    }

    private var entriesByFont: [StandardFont: Entry]

    init(fonts: PDFOptions.EmbeddedFonts) throws {
        var entries: [StandardFont: Entry] = [:]
        try Self.add(fonts.regular, for: .helvetica, resourceName: "EF1", to: &entries)
        try Self.add(fonts.bold, for: .helveticaBold, resourceName: "EF2", to: &entries)
        try Self.add(fonts.italic, for: .helveticaOblique, resourceName: "EF3", to: &entries)
        try Self.add(fonts.monospaced, for: .courier, resourceName: "EF4", to: &entries)
        entriesByFont = entries
    }

    func entry(for font: StandardFont) -> Entry? {
        entriesByFont[font]
    }

    func width(of run: PDFTextRun, fallbackFontSet: PDFOptions.FontSet) throws -> Double {
        guard let entry = entry(for: run.font) else {
            return run.width(fontSet: fallbackFontSet)
        }

        return try mapping(for: run, entry: entry).totalWidth
    }

    func mapping(for run: PDFTextRun, entry: Entry) throws -> TrueTypeGlyphMapper.TextMapping {
        try entry.mapper.map(text: run.text, fontSize: run.size)
    }

    private static func add(
        _ source: PDFOptions.EmbeddedFontSource?,
        for font: StandardFont,
        resourceName: String,
        to entries: inout [StandardFont: Entry],
    ) throws {
        guard let source else {
            return
        }

        let metadata = try TrueTypeFontParser().parse(source.data)
        let resource = PDFEmbeddedFontResource(
            resourceName: resourceName,
            fontProgram: source.data,
            metadata: metadata,
            baseName: source.baseName,
        )
        entries[font] = Entry(
            resource: resource,
            mapper: TrueTypeGlyphMapper(data: source.data, metadata: metadata),
        )
    }
}
