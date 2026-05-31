# MarkdownPDF

MarkdownPDF is a Pure Swift Markdown to PDF renderer. It parses Markdown, lays it
out, and writes PDF bytes directly in Swift. It does not use PDFKit,
CoreGraphics, WebKit, wkhtmltopdf, Chromium, LaTeX, or C Markdown/PDF libraries.

The package is designed to build on macOS and Linux. The default PDF font names
are Apple system fonts (`SFProText` and `SFMono`) without embedding font files.
PDF viewers that do not have those fonts may substitute a local font.

## Status

Early implementation. The project contract is CommonMark plus GitHub Flavored
Markdown tables and images. The first renderer covers headings, paragraphs,
emphasis, strong text, strike-through, inline code, links, local JPEG and PNG
images, block quotes, ordered and unordered lists, fenced code blocks, thematic
breaks, raw HTML as visible text, and tables.

See [docs/DESIGN.md](docs/DESIGN.md) for the architecture.

## Use

```swift
import MarkdownPDF

let markdown = "# Hello\n\nA small PDF renderer."
let data = try MarkdownPDFRenderer().render(markdown: markdown)
try data.write(to: URL(fileURLWithPath: "hello.pdf"))
```

Command line:

```sh
cd Packages
swift run markdownpdf input.md output.pdf
```

## Build

```sh
cd Packages
swift build
swift test
```

## Design constraints

- Pure Swift source.
- No runtime shell-out to another renderer.
- No font embedding in the public repo.
- Apple font names by default, with PDF base fonts available through
  `PDFOptions.FontSet.pdfBase`.
- Linux generation support through Foundation and byte-level PDF serialization.

## License

See [LICENSE](LICENSE).
