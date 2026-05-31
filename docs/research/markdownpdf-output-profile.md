# MarkdownPDF portable PDF output profile

Date: 2026-05-31

This note chooses the initial deterministic PDF output profile for MarkdownPDF's
portable Swift writer. It turns the canonical PDF structure research into
writer and test expectations.

## Scope

This profile applies to the portable renderer that must run on Linux and macOS.
It is not macOS-only and not iOS-only. It does not use PDFKit, CoreGraphics,
CoreText, WebKit, browser drivers, LaTeX, C renderers, or external PDF
libraries.

The profile describes PDF bytes, not a layout algorithm. Layout features can
change without changing this profile as long as they emit the same structural
PDF shape.

## Baseline decision

MarkdownPDF's first portable profile is:

- Complete non-incremental PDF file.
- PDF 1.4 header.
- Classic xref table.
- Trailer dictionary with `/Size` and `/Root`.
- Catalog plus flat page tree.
- Page dictionaries with direct resource dictionaries.
- Content streams with exact `/Length`.
- Standard PDF base fonts by default.
- Image XObjects for supported images.
- Link annotations for URI links.
- No object streams, xref streams, encryption, signatures, linearization, tagged
  PDF, PDF/A, or PDF/UA in the baseline.

This is intentionally conservative. It matches the current writer shape and is
widely supported by readers.

## Object order

The initial writer should use deterministic object numbering and object order:

1. Catalog object.
2. Pages root object.
3. Font objects.
4. Image XObjects.
5. Page content streams.
6. Annotation objects.
7. Page objects.
8. Future optional document-level objects, only when enabled.

The current `PDFDocumentWriter` reserves catalog and pages references first, then
fills them after page and resource objects are known. That is acceptable and
should remain the model until a typed object writer replaces the current builder.

All in-use objects use generation 0. Object numbers should not depend on hash
iteration order, filesystem order, random IDs, timestamps, or platform-specific
state.

## Header and file ending

The file starts with:

```text
%PDF-1.4
% binary-marker-comment
```

The second line may contain arbitrary bytes above ASCII 127 to signal that the
file should be treated as binary.

The file ends with:

```text
xref
0 N
0000000000 65535 f
...
trailer
<< /Size N /Root 1 0 R >>
startxref
byte-offset-of-xref
%%EOF
```

`startxref` must be the byte offset of the `xref` keyword. Tests should validate
that every in-use xref entry points to the matching object header.

## Catalog and pages

The catalog baseline is:

```text
<< /Type /Catalog /Pages 2 0 R >>
```

Optional catalog entries are added only when the corresponding feature is
implemented and tested. Examples are `/Outlines`, `/Names`, `/Metadata`,
`/MarkInfo`, `/StructTreeRoot`, and `/ViewerPreferences`.

The pages root baseline is a flat tree:

```text
<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>
```

The writer can move to a deeper page tree later if document size makes that
worthwhile. The first profile should keep the tree flat because it is easier to
inspect and test.

Each page dictionary includes:

```text
<< /Type /Page
/Parent 2 0 R
/MediaBox [0 0 width height]
/Resources << ... >>
/Contents content-ref 0 R
>>
```

`/Annots` is present only when the page has annotations.

## Resources

Resource dictionaries are explicit. The writer must know which fonts, images,
graphics states, and future form XObjects a page uses before writing the page
dictionary.

The baseline resource dictionary includes `/Font` and optional `/XObject`:

```text
<<
/Font << /F1 font-ref 0 R /F2 font-ref 0 R >>
/XObject << /I1 image-ref 0 R >>
>>
```

Resource names are deterministic:

- Standard fonts keep the existing `F1`, `F2`, `F3`, `F4` names.
- Images use deterministic names assigned by the renderer.
- Future embedded fonts continue the `F` sequence or use a deterministic
  registry chosen by the typed writer.
- Future graphics states use a deterministic `GS` sequence.

Resources should be tracked while draw commands are emitted. The writer should
not infer resource usage by scanning content stream strings.

## Content streams

Every page has one content stream in the first profile. A later typed writer may
split page content into multiple streams, but doing so must preserve the page
dictionary `/Contents` invariant.

Every stream dictionary includes an exact `/Length` value. Uncompressed page
content is acceptable for the baseline because it keeps tests simple. Compression
can be enabled later if tests validate `/Filter`, `/Length`, and decoded content
where needed.

Content streams use PDF operators directly. Layout code should move toward typed
draw commands and a typed content-stream builder, but the profile does not
require that refactor before the current structural tests pass.

## Fonts

The default profile uses standard PDF base fonts and does not embed font files.
The default public font set should remain based on Helvetica, Helvetica-Bold,
Helvetica-Oblique, and Courier.

The `appleSystem` font set is an opt-in naming surface. It must not make the
portable writer depend on Apple frameworks. It also must not be treated as
article-grade embedded font support.

The first embedded-font profile, when implemented, should target:

- Type0 composite font.
- CIDFontType2 descendant.
- `/Identity-H` encoding.
- FontDescriptor.
- `/FontFile2` TrueType subset stream.
- `/W` widths.
- `/CIDToGIDMap` as `/Identity` or an explicit stream.
- `/ToUnicode` CMap stream.

That future work must include structural tests for the full font object graph.
It must not commit font files to the public repository unless the font license is
reviewed and the repo policy changes.

## Images

Image support remains XObject-based:

```text
<< /Type /XObject
/Subtype /Image
/Width w
/Height h
/ColorSpace ...
/BitsPerComponent ...
/Filter ...
>>
stream
image bytes
endstream
```

JPEG uses `DCTDecode`. Supported PNG input uses compressed image data with the
matching predictor parameters. New image formats must preserve direct PDF byte
generation in Swift and must build on Linux.

## Links and navigation

URI links are emitted as page annotations:

```text
<< /Type /Annot
/Subtype /Link
/Rect [x0 y0 x1 y1]
/Border [0 0 0]
/A << /S /URI /URI (...) >>
>>
```

Internal links, outlines, named destinations, and ToC entries are not baseline
features yet. They should be added after layout produces stable heading anchors.
The intended order is:

1. Layout anchors for headings and explicit IDs.
2. Destination objects or destination arrays.
3. Link annotations for internal destinations.
4. Outline dictionary and outline item tree.
5. Table of contents generated from settled layout results.

ToC is a layout feature before it is a PDF feature. The writer should not invent
page numbers from parser order.

## Metadata

The baseline profile does not require `/Info`, `/Metadata`, or `/ID`.

When metadata is added:

- `/Info` is referenced from the trailer.
- XMP `/Metadata` is referenced from the catalog.
- `/ID` is generated deterministically only if the validation target allows that,
  or generated from stable file content when nondeterminism is acceptable.

PDF/A and PDF/UA are separate profiles. They require additional constraints and
must not be claimed by the baseline.

## Validation requirements

Tests for this profile should assert:

- Header starts with `%PDF-1.4`.
- The file contains a classic xref table.
- The free xref entry is object 0 generation 65535.
- In-use xref offsets point to object headers.
- Trailer `/Size` matches xref count.
- Trailer `/Root` points to a catalog.
- `startxref` points to `xref`.
- The pages tree `/Count` matches leaf page count.
- Every page has `/Parent`, `/MediaBox`, `/Resources`, and `/Contents`.
- Every stream `/Length` matches emitted bytes.
- Page resource names cover every used font and image name.
- Base-font output does not contain `/FontFile`, `/FontFile2`, or `/FontFile3`.
- Link annotation count and URI actions match rendered links.

Future tests for embedded fonts, outlines, metadata, tagged PDF, and PDF/A should
extend this list rather than weakening it.

## Deferred profile decisions

The following remain explicit future profiles or feature decisions:

- PDF 1.5 or later xref streams and object streams.
- Incremental update writing.
- Linearized PDF.
- Encryption and permissions.
- Digital signatures.
- Tagged PDF and PDF/UA.
- PDF/A metadata, output intents, and conformance declarations.
- Embedded CFF fonts and color fonts.
- Complex-script shaping and bidirectional text layout.
- SVG and graph vector import.

Deferring these keeps the portable writer small enough to test thoroughly on both
Linux and macOS.

