# Contributing to MarkdownPDF

MarkdownPDF is a Pure Swift project. All renderer, parser, PDF writer, CLI, and
test code must be Swift.

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting Started

```sh
git config core.hooksPath .githooks
cd Packages
swift build
swift test
```

Run the CLI:

```sh
swift run markdownpdf input.md output.pdf
```

## Constraints

- No PDFKit, CoreGraphics, WebKit, browser automation, LaTeX, or external PDF
  renderers.
- No C Markdown or PDF libraries.
- No font files committed to this repo.
- The core must build on macOS and Linux.
- Tests use Swift Testing.

## Commits

Commit messages follow Conventional Commits: `<type>(<scope>): summary`.
Examples: `feat(renderer): add table borders`, `test(parser): cover images`.

Do not include AI attribution and do not use em dashes in commit messages or
committed files.

## Pull Requests

- Keep one focused change per PR.
- Add tests for behavior changes.
- Run `swift build` and `swift test` from `Packages/`.
- Add a `CHANGELOG.md` entry for shipping source changes.

## License

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
