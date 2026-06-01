# Portable Mermaid flowchart subset

Date: 2026-06-01

## Scope

This note documents the first Mermaid support in the portable MarkdownPDF
renderer. The implementation is pure Swift and emits direct PDF drawing and text
operators. It applies to macOS and Linux because it does not use Apple-only APIs.
It does not claim iOS support.

No Node, JavaScript, browser renderer, shell renderer, PDFKit, CoreGraphics,
WebKit, LaTeX, C renderer, or external PDF library is involved.

## Supported syntax

The first subset supports Mermaid flowcharts with one statement per line:

```mermaid
flowchart TD
    Input[Markdown source] --> Parse[Block parser]
    Parse --> Layout[Article layout]
    Layout --> PDF[PDF bytes]
```

Supported graph headers:

- `flowchart TD`
- `flowchart TB`
- `flowchart BT`
- `flowchart LR`
- `flowchart RL`
- `graph` with the same directions

Omitting the direction defaults to top-bottom layout.

Supported node syntax:

- Bare node identifiers: `A`
- Rectangle labels: `A[Label]`
- Quoted rectangle labels: `A["Longer label"]`

Supported edge syntax:

- Solid directed edge: `A --> B`
- Solid directed edge with label: `A -->|label| B`

Node identifiers may contain letters, numbers, underscores, and hyphens. The
renderer records nodes in first-seen order, assigns deterministic graph layers,
and places nodes using deterministic spacing.

## Unsupported syntax

Unsupported Mermaid syntax is rendered as a visible code-block fallback with a
prefix that starts `Unsupported Mermaid diagram:`. This is deliberate. The
renderer must not pretend to support the full Mermaid language and must not call
out to platform-specific or external renderers.

Examples of unsupported syntax in the first subset:

- `sequenceDiagram`
- class diagrams, state diagrams, ER diagrams, Gantt charts, pie charts, and
  mind maps
- Styled nodes, classes, themes, subgraphs, shapes other than rectangles, and
  HTML labels
- Dashed or thick arrows such as `-.->`, `---`, or `==>`
- Cyclic flowcharts, because the first layout pass is a deterministic DAG layer
  layout

## Validation

The implementation is validated through:

- Unit tests for supported parsing, graph aliases, quoted labels, edge labels,
  and unsupported syntax.
- Renderer tests that check supported Mermaid labels are emitted as PDF text and
  the raw Mermaid source is not rendered for supported diagrams.
- Fallback tests that check unsupported syntax remains visible in extracted
  text.
- Fixture validation using the scientific article fixture.
- Poppler word-box and MuPDF character-quad visual layout tests, now including a
  Mermaid diagram, to catch label overlap.

## Platform note

This feature is portable macOS/Linux Swift. It is not macOS-only. It does not
use CoreGraphics or CoreText. It does not establish iOS support.
