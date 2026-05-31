// swift-tools-version: 6.1

import PackageDescription

#if os(macOS)
    let macProducts: [Product] = [
        .library(
            name: "MarkdownPDFMac",
            targets: ["MarkdownPDFMac"],
        ),
    ]

    let macTargets: [Target] = [
        .target(
            name: "MarkdownPDFMac",
            dependencies: ["MarkdownPDF"],
        ),
    ]

    let macTestDependencies: [Target.Dependency] = ["MarkdownPDFMac"]
#else
    let macProducts: [Product] = []
    let macTargets: [Target] = []
    let macTestDependencies: [Target.Dependency] = []
#endif

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
            name: "MarkdownPDFLinux",
            targets: ["MarkdownPDFLinux"],
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
    ] + macProducts,
    targets: [
        .target(
            name: "MarkdownPDF",
        ),
        .target(
            name: "MarkdownPDFLinux",
            dependencies: ["MarkdownPDF"],
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
            dependencies: ["MarkdownPDF", "MarkdownPDFLinux"] + macTestDependencies,
            exclude: ["Fixtures"],
        ),
        .testTarget(
            name: "MarkdownPDFResumeTests",
            dependencies: ["MarkdownPDF", "MarkdownPDFResume"],
            exclude: ["Fixtures"],
        ),
    ] + macTargets,
)
