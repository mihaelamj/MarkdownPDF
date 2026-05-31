# Design: MarkdownPDF

| Field | Value |
|---|---|
| Status | draft |
| Created | 2026-05-31 |
| Last revised | 2026-05-31 |

## Summary

MarkdownPDF converts Markdown to PDF with no external renderer. The core path is
Markdown text, Swift parser, Swift layout, Swift PDF serialization, PDF bytes.
The first implementation is intentionally small, but the compatibility target is
CommonMark plus GitHub Flavored Markdown tables and images.

## Goals

- Build and test on macOS and Linux.
- Keep source Pure Swift.
- Render PDFs without PDFKit, CoreGraphics, WebKit, browser automation, LaTeX,
  or C libraries.
- Use Apple font names by default without embedding font files.
- Support Markdown block and inline syntax, including tables and images.

## Non-Goals

- No font redistribution.
- No browser-quality CSS layout.
- No runtime shell-out to another conversion tool.

## Architecture

```
Markdown source
  -> MarkdownParser
  -> MarkdownDocument
  -> MarkdownPDFRenderer layout
  -> PDFDocumentWriter
  -> Data
```

## Components

`MarkdownParser` builds the AST from Markdown source. It owns block parsing and
uses `InlineParser` for inline spans.

`MarkdownPDFRenderer` turns the AST into positioned drawing operations. It
handles pagination, wrapping, list markers, table grid drawing, image placement,
and text styling.

`PDFDocumentWriter` serializes a compact PDF file. It writes the catalog, pages,
resource dictionaries, content streams, cross-reference table, text resources,
and image XObjects directly.

`PDFImage` reads local JPEG and PNG files. JPEG data is embedded through
`DCTDecode`. Supported PNG files are embedded through their existing compressed
IDAT bytes with PDF PNG predictor parameters.

## Font Policy

The default font set references Apple system font names:

- `SFProText-Regular`
- `SFProText-Bold`
- `SFProText-RegularItalic`
- `SFMono-Regular`

The repo does not embed or redistribute those font files. PDF viewers that lack
the fonts may substitute. `PDFOptions.FontSet.pdfBase` switches to standard PDF
base fonts when strict portability of visual appearance matters more than Apple
font naming.

## Compatibility Target

The target is CommonMark plus GitHub Flavored Markdown tables and images. The
current implementation covers the syntax listed in the README and should grow
through parser fixtures and renderer tests.
