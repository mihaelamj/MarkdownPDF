// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MarkdownPDF",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "MarkdownPDF",
            targets: ["MarkdownPDF"],
        ),
        .executable(
            name: "markdownpdf",
            targets: ["MarkdownPDFCLI"],
        ),
    ],
    targets: [
        .target(
            name: "MarkdownPDF",
        ),
        .executableTarget(
            name: "MarkdownPDFCLI",
            dependencies: ["MarkdownPDF"],
        ),
        .testTarget(
            name: "MarkdownPDFTests",
            dependencies: ["MarkdownPDF"],
        ),
    ],
)
