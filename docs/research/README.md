# Research notes

This directory is the map for MarkdownPDF research records. Research notes are
inputs to implementation work, not product behavior until the behavior exists in
Swift source and tests.

## Read order

1. Start with `canonical-pdf-document-structure.md` for the target PDF file
   structure.
2. Read `markdownpdf-output-profile.md` to understand the current portable
   output profile.
3. Use `existing-pdf-writer-alignment.md` to connect source research to the
   current implementation plan.
4. Use `pdf-type-modeling-policy.md` before adding new PDF model types.
5. Use `pdf-validation-tooling.md` and `pdf-visual-layout-validation.md` before
   changing tests or CI validation.
6. Use the source studies when planning new writer features.
7. Use macOS-specific research only for macOS targets. It is not a Linux or iOS
   implementation plan.

## Boundaries

- The core renderer must remain Pure Swift and Linux-buildable.
- Research can describe external libraries, papers, tools, and operating system
  APIs, but implementation in this repo must generate PDF bytes directly.
- macOS-specific findings must say macOS-specific. They do not imply iOS support.
- Useful research results belong in this directory.
- Source snapshots, when present, are research evidence and not package
  dependencies. See `source-snapshot-policy.md`.

## File map

| File | Purpose |
|---|---|
| `canonical-pdf-document-structure.md` | Canonical PDF object structure, xref, trailer, pages, resources, streams, outlines, and validation expectations. |
| `markdownpdf-output-profile.md` | The portable output profile MarkdownPDF aims to emit and document. |
| `pdf-type-modeling-policy.md` | Policy for adding internal typed PDF model structures. |
| `existing-pdf-writer-alignment.md` | Alignment notes between existing writer behavior and research findings. |
| `pdf-validation-tooling.md` | Open source validation tools and the current CI validation strategy. |
| `pdf-visual-layout-validation.md` | Visual layout validation strategy using text and render extraction tools. |
| `deep-portable-pdf-source-study.md` | Deeper study of portable PDF implementations and architecture patterns. |
| `existing-pdf-products-source-study.md` | Survey of existing products and libraries that produce PDFs. |
| `open-source-pdf-library-porting.md` | Notes on which open source ideas can be translated into Swift without taking dependencies. |
| `pdf-rendering-literature-review.md` | Scientific and technical literature relevant to PDF rendering, layout, and validation. |
| `mac-pdf-renderer-research.md` | macOS PDF rendering research. macOS only unless explicitly stated otherwise. |

## Updating this directory

When adding a research note:

- Add the new file to the file map.
- State whether the finding is portable macOS/Linux, macOS-only, or not suitable
  for implementation.
- Prefer source links and reproducible observations over summaries.
- Keep implementation recommendations separate from research evidence.
- Do not cite private absolute paths or machine-specific paths.
