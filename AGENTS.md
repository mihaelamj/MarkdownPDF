# Agent Guide

Guidance for anyone writing code in MarkdownPDF.

## What MarkdownPDF Is

MarkdownPDF is a Pure Swift Markdown to PDF renderer. The library parses
Markdown into an AST, lays the document out, and serializes a PDF file by hand.
The CLI is `markdownpdf`. The code must build on macOS and Linux.

## Rule Loading

At the start of a session, read [docs/rules/README.md](docs/rules/README.md) and
the rules it marks as always relevant. Name the rule files that apply to the
task at hand.

## Language Policy

Swift only for source, tests, and tooling. Do not add JavaScript, Python, shell
renderers, browser drivers, PDFKit, CoreGraphics, WebKit, LaTeX, or C Markdown
or PDF libraries.

## Product Rules

- Generate PDF bytes directly in Swift.
- Keep the core Linux-buildable.
- Do not embed font files in the public repo.
- Use Apple system font names by default (`SFProText` and `SFMono`), with
  substitute rendering expected on systems without those fonts.
- Treat CommonMark plus GitHub Flavored Markdown tables and images as the
  compatibility target.
- Keep public API small and testable.

## Workflow

- Verify before claiming done: run `swift build` and `swift test` from
  `Packages/` and cite the output.
- Commits follow Conventional Commits.
- No AI attribution and no em dashes in any committed text. Enable hooks with
  `git config core.hooksPath .githooks`.

## Commands

```sh
cd Packages
swift build
swift test
swift run markdownpdf input.md output.pdf
```
