# MarkdownPDF

MarkdownPDF is a Pure Swift Markdown to PDF renderer. It parses Markdown, lays it
out, and writes PDF bytes directly in Swift. It does not use PDFKit,
CoreGraphics, WebKit, wkhtmltopdf, Chromium, LaTeX, or C Markdown/PDF libraries.

The package is designed to build on macOS and Linux. The default font set uses
standard PDF base fonts for portable text layout without embedding font files.
Apple system font names remain available through `PDFOptions.FontSet.appleSystem`.

## Status

Early implementation. The compatibility target is CommonMark plus GitHub
Flavored Markdown tables and images. The first renderer currently covers
headings, paragraphs, emphasis, strong text, strike-through, inline code, links,
local JPEG and PNG images, block quotes, ordered and unordered lists, fenced
code blocks, thematic breaks, raw HTML as visible text, and tables.

The resume and CV template is separate from the generic renderer. It lives in
the `MarkdownPDFResume` target and emits Markdown from structured resume JSON.
The `resumepdf` executable combines that template with the generic renderer.

The package also exposes platform entry products. `MarkdownPDFLinux` is the
portable renderer entry point for Linux-compatible generation.
`MarkdownPDFMac` is a macOS-only entry point reserved for a future native macOS
backend; it currently delegates to the portable renderer.

See [docs/DESIGN.md](docs/DESIGN.md) for the architecture.

## Canonical PDF roadmap

Epic [#27](https://github.com/mihaelamj/MarkdownPDF/issues/27) tracks the
ordered path from the current byte writer to a fully typed canonical PDF
document structure.

```mermaid
flowchart TD
    P0["Phase 0<br/>#28 Minimal canonical PDF<br/>Done"]
    P1["Phase 1<br/>#29 Tool validation<br/>#25 Structural validation<br/>Done"]
    P2["Phase 2<br/>#22 PDF syntax<br/>#30 Object registry, xref, trailer<br/>Done"]
    P3["Phase 3<br/>#18 Catalog, page tree, page dictionaries<br/>Next"]
    P4["Phase 4<br/>#19 Page resources<br/>#20 Font objects<br/>#23 Image XObjects"]
    P5["Phase 5<br/>#21 Typed content streams"]
    P6["Phase 6<br/>#26 Metadata, outlines, destinations"]
    P7["Phase 7<br/>#24 Output profile documentation"]

    P0 --> P1 --> P2 --> P3 --> P4 --> P5 --> P6 --> P7

    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#111;
    classDef next fill:#fff8e1,stroke:#f9a825,color:#111;
    classDef todo fill:#eef3ff,stroke:#3367d6,color:#111;
    class P0,P1,P2 done;
    class P3 next;
    class P4,P5,P6,P7 todo;
```

## Use

```swift
import MarkdownPDF

let markdown = "# Hello\n\nA small PDF renderer."
let data = try MarkdownPDFRenderer().render(markdown: markdown)
try data.write(to: URL(fileURLWithPath: "hello.pdf"))
```

Portable Linux-facing product:

```swift
import MarkdownPDFLinux

let data = try MarkdownPDFLinuxRenderer().render(markdown: markdown)
```

macOS-facing product:

```swift
import MarkdownPDFMac

let data = try MarkdownPDFMacRenderer().render(markdown: markdown)
```

Command line:

```sh
cd Packages
swift run markdownpdf input.md output.pdf
```

Resume template command line:

```sh
cd Packages
swift run resumepdf input.json output.pdf
```

See [docs/RESUME_TEMPLATE.md](docs/RESUME_TEMPLATE.md) for the template and
journal inputs behind it.

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
- Standard PDF base fonts by default, with Apple system font names available
  through `PDFOptions.FontSet.appleSystem`.
- Linux generation support through Foundation and byte-level PDF serialization.

## License

See [LICENSE](LICENSE).
