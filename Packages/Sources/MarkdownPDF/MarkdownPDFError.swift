import Foundation

public enum MarkdownPDFError: Error, Equatable, LocalizedError, Sendable {
    case unreadableImage(String)
    case unsupportedImage(String)
    case invalidImage(String)
    case tableOfContentsDidNotConverge(maxPasses: Int)

    public var errorDescription: String? {
        switch self {
        case let .unreadableImage(path):
            "Could not read image at \(path)."
        case let .unsupportedImage(path):
            "Unsupported image format at \(path). Supported formats are JPEG and PNG without interlaced alpha."
        case let .invalidImage(path):
            "Invalid image data at \(path)."
        case let .tableOfContentsDidNotConverge(maxPasses):
            "Generated table of contents page numbers did not converge after \(maxPasses) layout passes."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unreadableImage:
            "Confirm the image path is relative to the input document or pass the correct assetsBaseURL."
        case .unsupportedImage:
            "Use a local JPEG or PNG image supported by MarkdownPDF."
        case .invalidImage:
            "Replace the image with valid JPEG or PNG data."
        case .tableOfContentsDidNotConverge:
            "Reduce pagination churn around headings or render without a generated table of contents."
        }
    }
}
