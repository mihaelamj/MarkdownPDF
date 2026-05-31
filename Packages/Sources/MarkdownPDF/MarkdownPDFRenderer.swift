import Foundation

public struct MarkdownPDFRenderer: Sendable {
    public var options: PDFOptions

    public init(options: PDFOptions = PDFOptions()) {
        self.options = options
    }

    public func render(
        markdown: String,
        assetsBaseURL: URL? = nil,
    ) throws -> Data {
        let document = MarkdownParser().parse(markdown)
        var layout = Layout(options: options, assetsBaseURL: assetsBaseURL)
        try layout.render(document)
        return layout.pdfData()
    }
}

private struct Layout {
    var options: PDFOptions
    var assetsBaseURL: URL?
    var pages: [PDFPageCanvas] = [PDFPageCanvas()]
    var images: [PDFImage] = []
    var y: Double
    var listDepth = 0

    init(options: PDFOptions, assetsBaseURL: URL?) {
        self.options = options
        self.assetsBaseURL = assetsBaseURL
        y = options.pageSize.height - options.margins.top
    }

    mutating func render(_ document: MarkdownDocument) throws {
        for (index, block) in document.blocks.enumerated() {
            keepHeadingWithNextBlock(block, isLast: index == document.blocks.count - 1)
            try render(block)
        }
    }

    func pdfData() -> Data {
        PDFDocumentWriter(
            pageSize: options.pageSize,
            fontSet: options.fontSet,
            pages: pages,
            images: images,
            title: options.title,
        ).data()
    }

    private mutating func render(_ block: MarkdownBlock) throws {
        switch block {
        case let .heading(level, content):
            let size = headingSize(level)
            let topSpacing = headingTopSpacing(level)
            ensureSpace(size * 1.8 + topSpacing)
            addHeadingTopSpacing(topSpacing)
            drawWrapped(
                flatten(content, font: .helveticaBold, size: size),
                x: options.margins.left,
                maxWidth: contentWidth,
                lineHeight: size * 1.25,
            )
            y -= size * 0.5
        case let .paragraph(content):
            if try renderStandaloneImage(content) {
                y -= 12
            } else {
                drawWrapped(
                    flatten(content, font: .helvetica, size: options.baseFontSize),
                    x: options.margins.left,
                    maxWidth: contentWidth,
                    lineHeight: bodyLineHeight,
                )
                y -= paragraphSpacing
            }
        case let .blockQuote(blocks):
            ensureSpace(24)
            let left = options.margins.left
            currentPage.drawLine(
                x1: left,
                y1: y + 6,
                x2: left,
                y2: max(options.margins.bottom, y - 42),
                width: 2,
                color: .gray,
            )
            let savedLeft = options.margins.left
            options.margins.left += 14
            for nested in blocks {
                try render(nested)
            }
            options.margins.left = savedLeft
        case let .unorderedList(items):
            try renderList(items: items, start: nil)
        case let .orderedList(start, items):
            try renderList(items: items, start: start)
        case let .codeBlock(_, code):
            renderCodeBlock(code)
        case let .table(table):
            renderTable(table)
        case .thematicBreak:
            ensureSpace(18)
            currentPage.drawLine(
                x1: options.margins.left,
                y1: y,
                x2: options.pageSize.width - options.margins.right,
                y2: y,
                width: 0.75,
                color: .gray,
            )
            y -= 18
        case let .html(html):
            drawWrapped(
                [PDFTextRun(text: html, font: .courier, size: options.baseFontSize * 0.9, color: .gray)],
                x: options.margins.left,
                maxWidth: contentWidth,
                lineHeight: options.baseFontSize * 1.35,
            )
            y -= 9
        }
    }

    private mutating func renderList(
        items: [MarkdownBlock.ListItem],
        start: Int?,
    ) throws {
        var number = start ?? 0
        listDepth += 1
        defer { listDepth -= 1 }
        for item in items {
            ensureSpace(bodyLineHeight)
            if start != nil {
                currentPage.drawTextRun(
                    PDFTextRun(text: "\(number).", font: .helvetica, size: options.baseFontSize),
                    x: options.margins.left,
                    y: y,
                    fontSet: options.fontSet,
                )
                number += 1
            }
            let savedLeft = options.margins.left
            options.margins.left += 24
            for block in item.blocks {
                try render(block)
            }
            options.margins.left = savedLeft
        }
        y -= listTrailingSpacing
    }

    private mutating func renderCodeBlock(_ code: String) {
        let size = options.baseFontSize * 0.9
        let lineHeight = size * 1.4
        let lines = code.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let height = max(lineHeight, Double(lines.count) * lineHeight) + 12
        ensureSpace(height)

        currentPage.drawRectangle(
            x: options.margins.left - 4,
            y: y - height + 4,
            width: contentWidth + 8,
            height: height,
            stroke: nil,
            fill: PDFColor(red: 0.95, green: 0.95, blue: 0.95),
        )

        for line in lines {
            currentPage.drawTextRun(
                PDFTextRun(text: line, font: .courier, size: size),
                x: options.margins.left,
                y: y - size,
                fontSet: options.fontSet,
            )
            y -= lineHeight
        }
        y -= 12
    }

    private mutating func renderTable(_ table: MarkdownBlock.Table) {
        let columns = max(1, table.headers.count)
        let columnWidth = contentWidth / Double(columns)
        let cellPadding = 4.0
        let fontSize = options.baseFontSize * 0.9
        let lineHeight = fontSize * 1.35

        renderTableRow(
            cells: table.headers,
            alignments: table.alignments,
            columnWidth: columnWidth,
            cellPadding: cellPadding,
            fontSize: fontSize,
            lineHeight: lineHeight,
            header: true,
        )

        for row in table.rows {
            renderTableRow(
                cells: row,
                alignments: table.alignments,
                columnWidth: columnWidth,
                cellPadding: cellPadding,
                fontSize: fontSize,
                lineHeight: lineHeight,
                header: false,
            )
        }

        y -= 12
    }

    private mutating func renderTableRow(
        cells: [[MarkdownInline]],
        alignments: [MarkdownBlock.Alignment],
        columnWidth: Double,
        cellPadding: Double,
        fontSize: Double,
        lineHeight: Double,
        header: Bool,
    ) {
        let cellLines = cells.map {
            wrappedLines(
                flatten($0, font: header ? .helveticaBold : .helvetica, size: fontSize),
                maxWidth: columnWidth - cellPadding * 2,
            )
        }
        let maxLines = max(1, cellLines.map(\.count).max() ?? 1)
        let rowHeight = Double(maxLines) * lineHeight + cellPadding * 2
        ensureSpace(rowHeight)

        let rowBottom = y - rowHeight
        for column in 0 ..< cells.count {
            let x = options.margins.left + Double(column) * columnWidth
            currentPage.drawRectangle(
                x: x,
                y: rowBottom,
                width: columnWidth,
                height: rowHeight,
                stroke: .gray,
                fill: header ? PDFColor(red: 0.93, green: 0.93, blue: 0.93) : nil,
            )

            var lineY = y - cellPadding - fontSize
            for line in cellLines[column] {
                let width = line.reduce(0) { $0 + $1.width(fontSet: options.fontSet) }
                let alignment = column < alignments.count ? alignments[column] : .leading
                let textX = switch alignment {
                case .leading:
                    x + cellPadding
                case .center:
                    x + (columnWidth - width) / 2
                case .trailing:
                    x + columnWidth - cellPadding - width
                }
                drawRuns(line, x: textX, y: lineY)
                lineY -= lineHeight
            }
        }
        y = rowBottom
    }

    private mutating func renderStandaloneImage(_ content: [MarkdownInline]) throws -> Bool {
        guard content.count == 1,
              case let .image(alt, source, _) = content[0]
        else {
            return false
        }

        if source.hasPrefix("http://") || source.hasPrefix("https://") {
            drawWrapped(
                [PDFTextRun(text: "[Remote image: \(alt.isEmpty ? source : alt)]", font: .helveticaOblique, size: options.baseFontSize, color: .gray)],
                x: options.margins.left,
                maxWidth: contentWidth,
                lineHeight: options.baseFontSize * 1.35,
            )
            return true
        }

        let name = "Im\(images.count + 1)"
        let image = try PDFImage.load(source: source, baseURL: assetsBaseURL, name: name)
        images.append(image)

        let maxWidth = contentWidth
        let maxHeight = options.pageSize.height * 0.45
        let widthScale = maxWidth / Double(image.width)
        let heightScale = maxHeight / Double(image.height)
        let scale = min(1, widthScale, heightScale)
        let drawWidth = Double(image.width) * scale
        let drawHeight = Double(image.height) * scale

        ensureSpace(drawHeight)
        currentPage.drawImage(
            name: image.name,
            x: options.margins.left,
            y: y - drawHeight,
            width: drawWidth,
            height: drawHeight,
        )
        y -= drawHeight
        return true
    }

    private func flatten(
        _ inlines: [MarkdownInline],
        font: StandardFont,
        size: Double,
        color: PDFColor = .black,
        underline: Bool = false,
        strikethrough: Bool = false,
        linkDestination: String? = nil,
    ) -> [PDFTextRun] {
        var runs: [PDFTextRun] = []

        for inline in inlines {
            switch inline {
            case let .text(text):
                runs.append(PDFTextRun(text: text, font: font, size: size, color: color, underline: underline, strikethrough: strikethrough, linkDestination: linkDestination))
            case .softBreak:
                runs.append(PDFTextRun(text: " ", font: font, size: size, color: color, underline: underline, strikethrough: strikethrough, linkDestination: linkDestination))
            case .lineBreak:
                runs.append(PDFTextRun(text: "\n", font: font, size: size, color: color, underline: underline, strikethrough: strikethrough, linkDestination: linkDestination))
            case let .code(text):
                runs.append(PDFTextRun(
                    text: text,
                    font: .courier,
                    size: size * 0.95,
                    color: color,
                    underline: underline,
                    strikethrough: strikethrough,
                    linkDestination: linkDestination,
                ))
            case let .emphasis(children):
                runs.append(contentsOf: flatten(
                    children,
                    font: .helveticaOblique,
                    size: size,
                    color: color,
                    underline: underline,
                    strikethrough: strikethrough,
                    linkDestination: linkDestination,
                ))
            case let .strong(children):
                runs.append(contentsOf: flatten(
                    children,
                    font: .helveticaBold,
                    size: size,
                    color: color,
                    underline: underline,
                    strikethrough: strikethrough,
                    linkDestination: linkDestination,
                ))
            case let .strikethrough(children):
                runs.append(contentsOf: flatten(children, font: font, size: size, color: color, underline: underline, strikethrough: true, linkDestination: linkDestination))
            case let .link(children, destination, _):
                runs.append(contentsOf: flatten(children, font: font, size: size, color: .link, underline: true, strikethrough: strikethrough, linkDestination: destination))
            case let .image(alt, source, _):
                let label = alt.isEmpty ? source : alt
                runs.append(PDFTextRun(
                    text: "[Image: \(label)]",
                    font: .helveticaOblique,
                    size: size,
                    color: .gray,
                    underline: underline,
                    strikethrough: strikethrough,
                    linkDestination: linkDestination,
                ))
            }
        }

        return runs
    }

    private mutating func drawWrapped(
        _ runs: [PDFTextRun],
        x: Double,
        maxWidth: Double,
        lineHeight: Double,
    ) {
        for line in wrappedLines(runs, maxWidth: maxWidth) {
            ensureSpace(lineHeight)
            drawRuns(line, x: x, y: y)
            y -= lineHeight
        }
    }

    private func wrappedLines(
        _ runs: [PDFTextRun],
        maxWidth: Double,
    ) -> [[PDFTextRun]] {
        let tokens = tokenize(runs)
        var lines: [[PDFTextRun]] = []
        var current: [PDFTextRun] = []
        var currentWidth = 0.0

        for token in tokens {
            if token.text == "\n" {
                lines.append(current)
                current = []
                currentWidth = 0
                continue
            }

            let width = token.width(fontSet: options.fontSet)
            if currentWidth + width > maxWidth, !current.isEmpty {
                lines.append(current)
                current = [token]
                currentWidth = width
            } else {
                current.append(token)
                currentWidth += width
            }
        }

        if !current.isEmpty || lines.isEmpty {
            lines.append(current)
        }

        return lines
    }

    private func tokenize(_ runs: [PDFTextRun]) -> [PDFTextRun] {
        var tokens: [PDFTextRun] = []

        for run in runs {
            var buffer = ""
            for character in run.text {
                if character == "\n" {
                    if !buffer.isEmpty {
                        tokens.append(run.withText(buffer))
                        buffer = ""
                    }
                    tokens.append(run.withText("\n"))
                } else if character == " " || character == "\t" {
                    buffer.append(" ")
                    tokens.append(run.withText(buffer))
                    buffer = ""
                } else {
                    buffer.append(character)
                }
            }
            if !buffer.isEmpty {
                tokens.append(run.withText(buffer))
            }
        }

        return tokens
    }

    private func drawRuns(
        _ runs: [PDFTextRun],
        x: Double,
        y: Double,
    ) {
        var cursor = x
        for run in runs {
            currentPage.drawTextRun(run, x: cursor, y: y, fontSet: options.fontSet)
            cursor += run.width(fontSet: options.fontSet)
        }
    }

    private mutating func ensureSpace(_ height: Double) {
        if y - height < options.margins.bottom {
            pages.append(PDFPageCanvas())
            y = options.pageSize.height - options.margins.top
        }
    }

    private mutating func keepHeadingWithNextBlock(
        _ block: MarkdownBlock,
        isLast: Bool,
    ) {
        guard !isLast,
              case let .heading(level, _) = block
        else {
            return
        }

        let topSpacing = y < pageTopY - 1 ? headingTopSpacing(level) : 0
        let height = topSpacing + headingSize(level) * 1.8 + headingKeepWithNextHeight(level)
        ensureSpace(height)
    }

    private mutating func addHeadingTopSpacing(_ spacing: Double) {
        guard y < pageTopY - 1 else {
            return
        }

        y -= spacing
    }

    private func headingTopSpacing(_ level: Int) -> Double {
        switch level {
        case 1:
            options.baseFontSize * 1.4
        case 2:
            options.baseFontSize * 1.8
        case 3:
            options.baseFontSize * 1.45
        case 4:
            options.baseFontSize * 0.95
        default:
            options.baseFontSize * 0.5
        }
    }

    private func headingKeepWithNextHeight(_ level: Int) -> Double {
        switch level {
        case 1, 2:
            options.baseFontSize * 9.0
        case 3:
            options.baseFontSize * 4.5
        default:
            options.baseFontSize * 2.6
        }
    }

    private func headingSize(_ level: Int) -> Double {
        switch level {
        case 1:
            options.baseFontSize * 2.0
        case 2:
            options.baseFontSize * 1.55
        case 3:
            options.baseFontSize * 1.3
        default:
            options.baseFontSize * 1.1
        }
    }

    private var bodyLineHeight: Double {
        options.baseFontSize * (listDepth > 0 ? 1.15 : 1.24)
    }

    private var paragraphSpacing: Double {
        listDepth > 0 ? 2 : 6
    }

    private var listTrailingSpacing: Double {
        listDepth > 1 ? 1 : 3
    }

    private var contentWidth: Double {
        options.pageSize.width - options.margins.left - options.margins.right
    }

    private var pageTopY: Double {
        options.pageSize.height - options.margins.top
    }

    private var currentPage: PDFPageCanvas {
        pages[pages.count - 1]
    }
}

private extension PDFTextRun {
    func withText(_ newText: String) -> PDFTextRun {
        PDFTextRun(
            text: newText,
            font: font,
            size: size,
            color: color,
            underline: underline,
            strikethrough: strikethrough,
            linkDestination: linkDestination,
        )
    }
}
