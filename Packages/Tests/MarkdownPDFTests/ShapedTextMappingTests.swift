import Foundation
@testable import MarkdownPDF
import Testing

@Suite("Shaped text mapping")
struct ShapedTextMappingTests {
    @Test("Represents many-to-one ligature clusters")
    func representsManyToOneLigatureClusters() throws {
        let mapping = try ShapedTextMapping(
            sourceText: "fi",
            clusters: [
                ShapedTextMapping.Cluster(
                    sourceScalarRange: 0 ..< 2,
                    normalizedText: "fi",
                    glyphs: [
                        glyph(glyphID: 42, pdfCharacterCode: 7, advance: 6.5),
                    ],
                    toUnicodeScalars: ["f", "i"],
                ),
            ],
        )

        #expect(mapping.sourceScalarCount == 2)
        #expect(mapping.clusters[0].sourceScalarRange == 0 ..< 2)
        #expect(mapping.clusters[0].pdfCharacterCodes == [7])
        #expect(mapping.clusters[0].toUnicodeText == "fi")
        #expect(mapping.toUnicodeText == "fi")
        #expect(mapping.glyphs.map(\.glyphID) == [42])
        #expect(mapping.totalAdvance == 6.5)
    }

    @Test("Represents one-to-many and many-to-many clusters")
    func representsOneToManyAndManyToManyClusters() throws {
        let mapping = try ShapedTextMapping(
            sourceText: "Axy",
            clusters: [
                ShapedTextMapping.Cluster(
                    sourceScalarRange: 0 ..< 1,
                    normalizedText: "A",
                    glyphs: [
                        glyph(glyphID: 10, pdfCharacterCode: 10, advance: 4.0),
                        glyph(
                            glyphID: 11,
                            pdfCharacterCode: 11,
                            advance: 0,
                            offset: ShapedTextMapping.Offset(x: 1.25, y: 2.5),
                        ),
                    ],
                    toUnicodeScalars: ["A"],
                ),
                ShapedTextMapping.Cluster(
                    sourceScalarRange: 1 ..< 3,
                    normalizedText: "xy",
                    glyphs: [
                        glyph(glyphID: 20, pdfCharacterCode: 20, advance: 3.0),
                        glyph(glyphID: 21, pdfCharacterCode: 21, advance: 3.5),
                    ],
                    toUnicodeScalars: ["x", "y"],
                ),
            ],
        )

        #expect(mapping.clusters.map(\.sourceScalarRange) == [0 ..< 1, 1 ..< 3])
        #expect(mapping.clusters.map(\.pdfCharacterCodes) == [[10, 11], [20, 21]])
        #expect(mapping.clusters[0].glyphs[1].offset == ShapedTextMapping.Offset(x: 1.25, y: 2.5))
        #expect(mapping.toUnicodeText == "Axy")
        #expect(mapping.totalAdvance == 10.5)
    }

    @Test("Builds one-to-one clusters from TrueType glyph mappings")
    func buildsOneToOneClustersFromTrueTypeGlyphMappings() throws {
        let fontData = SyntheticTrueTypeFont.data()
        let metadata = try TrueTypeFontParser().parse(fontData)
        let textMapping = try TrueTypeGlyphMapper(data: fontData, metadata: metadata).map(text: "AB", fontSize: 12)

        let shapedText = try textMapping.shapedText()

        #expect(shapedText.sourceText == "AB")
        #expect(shapedText.clusters.map(\.sourceScalarRange) == [0 ..< 1, 1 ..< 2])
        #expect(shapedText.clusters.map(\.toUnicodeText) == ["A", "B"])
        #expect(shapedText.glyphs.map(\.glyphID) == [1, 2])
        #expect(shapedText.glyphs.map(\.cid) == [1, 2])
        #expect(shapedText.glyphs.map(\.pdfCharacterCode) == [1, 2])
        #expect(abs(shapedText.totalAdvance - textMapping.totalWidth) < 0.0001)
    }

    @Test("Rejects invalid cluster state with typed recovery")
    func rejectsInvalidClusterStateWithTypedRecovery() {
        do {
            _ = try ShapedTextMapping(
                sourceText: "A",
                clusters: [
                    ShapedTextMapping.Cluster(
                        sourceScalarRange: 0 ..< 2,
                        normalizedText: "A",
                        glyphs: [glyph()],
                        toUnicodeScalars: ["A"],
                    ),
                ],
            )
            Issue.record("Expected invalid shaped cluster range")
        } catch let error as ShapedTextMapping.ValidationError {
            #expect(error == .invalidSourceRange(lowerBound: 0, upperBound: 2, sourceScalarCount: 1))
            #expect(error.errorDescription != nil)
            #expect(error.recoverySuggestion != nil)
        } catch {
            Issue.record("Expected ShapedTextMapping.ValidationError, got \(error)")
        }
    }

    @Test("Rejects one-to-one conversion when glyph and scalar counts diverge")
    func rejectsOneToOneConversionWhenGlyphAndScalarCountsDiverge() {
        do {
            _ = try ShapedTextMapping.oneGlyphPerScalar(
                sourceText: "AB",
                glyphs: [trueTypeGlyph(scalar: "A")],
            )
            Issue.record("Expected source and glyph count mismatch")
        } catch let error as ShapedTextMapping.ValidationError {
            #expect(error == .sourceGlyphCountMismatch(sourceScalarCount: 2, glyphCount: 1))
            #expect(error.errorDescription != nil)
            #expect(error.recoverySuggestion != nil)
        } catch {
            Issue.record("Expected ShapedTextMapping.ValidationError, got \(error)")
        }
    }

    @Test("Rejects discontiguous source ranges")
    func rejectsDiscontiguousSourceRanges() {
        do {
            _ = try ShapedTextMapping(
                sourceText: "AB",
                clusters: [
                    ShapedTextMapping.Cluster(
                        sourceScalarRange: 1 ..< 2,
                        normalizedText: "B",
                        glyphs: [glyph()],
                        toUnicodeScalars: ["B"],
                    ),
                ],
            )
            Issue.record("Expected discontiguous shaped cluster range")
        } catch let error as ShapedTextMapping.ValidationError {
            #expect(error == .discontiguousSourceRange(expectedLowerBound: 0, actualLowerBound: 1))
            #expect(error.errorDescription != nil)
            #expect(error.recoverySuggestion != nil)
        } catch {
            Issue.record("Expected ShapedTextMapping.ValidationError, got \(error)")
        }
    }

    @Test("Rejects incomplete source coverage")
    func rejectsIncompleteSourceCoverage() {
        do {
            _ = try ShapedTextMapping(sourceText: "A", clusters: [])
            Issue.record("Expected incomplete shaped cluster coverage")
        } catch let error as ShapedTextMapping.ValidationError {
            #expect(error == .incompleteSourceCoverage(lastUpperBound: 0, sourceScalarCount: 1))
            #expect(error.errorDescription != nil)
            #expect(error.recoverySuggestion != nil)
        } catch {
            Issue.record("Expected ShapedTextMapping.ValidationError, got \(error)")
        }
    }

    private func glyph(
        glyphID: UInt16 = 1,
        pdfCharacterCode: UInt16 = 1,
        advance: Double = 6,
        offset: ShapedTextMapping.Offset = .zero,
    ) -> ShapedTextMapping.Glyph {
        ShapedTextMapping.Glyph(
            glyphID: glyphID,
            cid: glyphID,
            pdfCharacterCode: pdfCharacterCode,
            advanceWidth: 500,
            advance: advance,
            offset: offset,
        )
    }

    private func trueTypeGlyph(
        scalar: UnicodeScalar,
        glyphID: UInt16 = 1,
        pdfCharacterCode: UInt16 = 1,
    ) -> TrueTypeGlyphMapper.Glyph {
        TrueTypeGlyphMapper.Glyph(
            scalar: scalar,
            glyphID: glyphID,
            cid: glyphID,
            pdfCharacterCode: pdfCharacterCode,
            advanceWidth: 500,
            width: 6,
        )
    }
}
