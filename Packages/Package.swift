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
        .library(
            name: "MarkdownPDFResume",
            targets: ["MarkdownPDFResume"],
        ),
        .executable(
            name: "markdownpdf",
            targets: ["MarkdownPDFCLI"],
        ),
        .executable(
            name: "resumepdf",
            targets: ["ResumePDFCLI"],
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
        .target(
            name: "MarkdownPDFResume",
        ),
        .executableTarget(
            name: "ResumePDFCLI",
            dependencies: ["MarkdownPDF", "MarkdownPDFResume"],
        ),
        .testTarget(
            name: "MarkdownPDFTests",
            dependencies: ["MarkdownPDF"],
            exclude: ["Fixtures"],
        ),
        .testTarget(
            name: "MarkdownPDFResumeTests",
            dependencies: ["MarkdownPDF", "MarkdownPDFResume"],
            exclude: ["Fixtures"],
        ),
    ],
)
