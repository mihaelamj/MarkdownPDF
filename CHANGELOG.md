# Changelog

All notable changes to MarkdownPDF are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial Pure Swift Markdown parser, PDF renderer, and `markdownpdf` CLI.
- Direct PDF serialization with Apple font names and no embedded fonts.
- Parser and renderer tests for tables, images, inline styles, and PDF structure.
- `MarkdownPDFLinux` and `MarkdownPDFMac` renderer entry products.
- MuPDF character-quad and cross-renderer raster validation for generated PDFs.
- Deterministic PDF metadata, named heading destinations, outline objects, and
  internal heading links.
- Portable Mermaid flowchart rendering for a documented Swift-only subset, with
  visible fallback for unsupported Mermaid syntax.
- Portable embedded-font and ToUnicode implementation plan for future Type 0
  and CIDFontType2 work.
- Internal Type 0, CIDFontType2, FontFile2, and ToUnicode object models for the
  portable embedded-font profile.
- Pure Swift TrueType metadata parser with table bounds, checksums, cmap
  discovery, horizontal metrics, names, and OS/2 embedding policy gates.
- Internal TrueType glyph mapping and width measurement for the portable
  embedded-font profile.
- Deterministic ToUnicode CMap generation with range compression, chunking, and
  glyph-mapping conflict detection.
- Opt-in CID text writing, TrueType subsetting, CIDToGIDMap streams, and public
  `PDFOptions.EmbeddedFonts` role mapping for caller-provided TrueType data.
- CI-safe embedded-font fixtures using generated Swift TrueType data and an
  installed DejaVu Sans smoke-test path instead of committed font binaries.
- Opt-in portable syntax coloring for supported fenced code block language
  hints, with extraction, geometry, and raster witnesses.
- Opt-in TeX-style math typesetting through `PDFOptions.MathTypesetting`: a Pure
  Swift box-and-glue subset for inline and display math, scripts, fractions and
  radicals (typeset as 2D boxes inline and in display), big operators with
  limits, accents, `matrix`/`pmatrix`/`cases` environments, `\big`-style scaling
  delimiters, `\operatorname`, a broad symbol and Greek set, readable extraction
  text, and visible fallback for unsupported commands, with an optional
  font-backed mode that reads an embedded OpenType `MATH` table.
- Configurable `PDFOptions.Theme` styling with built-in default, dark, and print
  themes and a code-syntax color surface.
- GFM footnotes and task-list checkboxes.
- Native data-chart rendering for pie, bar, line, and xy charts.
- Opt-in Pure Swift `/FlateDecode` compression for page content streams and
  embedded FontFile2 streams.
- Opt-in tagged PDF structure output and PDF/UA-1 and PDF/A-2a conformance
  profiles verified with veraPDF on profile fixtures.
- Complex-script support: Unicode line-break opportunities (UAX #14),
  bidirectional ordering (UAX #9), shaped glyph clusters, and multi-scalar
  ToUnicode cluster mappings.
- Named page sizes through `PDFOptions.PageSize`: the A-series A0 through A6 plus
  `letter`, `legal`, and `tabloid`.
- Font outline and container format detection from the SFNT table directory,
  with typed, actionable rejection of OpenType CFF, WOFF, WOFF2, collections,
  CFF2, and variable fonts; `FontSet.appleSystem` documented as names-only and
  never embedded.
- A Swift-DocC documentation catalog as the single source of truth for project
  documentation.
- Multilingual (diacritic Latin, Cyrillic, Greek), CJK, and large-document test
  corpora rendered across the named page sizes.
- Study-only vendored algorithm references under `researchcode/` for DEFLATE,
  UAX #9 bidi, and UAX #14 line breaking.

### Changed

- Model PDF object registration, xref tables, trailers, and file envelopes as
  typed Swift structures.
- Model the PDF catalog, flat page tree, and page dictionaries as typed Swift
  structures.
- Track page resource usage and resource dictionaries through typed Swift
  structures.
- Model image XObjects and reusable image resource references through typed
  Swift structures.
- Build page content streams from typed PDF operator structures.
- Measure table column widths from header and body content, preserve alignment,
  and repeat table headers across page breaks.
- Validate Mermaid edge-label placement during planning and fall back visibly
  when labels would collide with diagram nodes.
