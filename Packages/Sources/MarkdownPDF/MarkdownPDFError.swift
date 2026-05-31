import Foundation

public enum MarkdownPDFError: Error, Equatable, LocalizedError, Sendable {
    case unreadableImage(String)
    case unsupportedImage(String)
    case invalidImage(String)

    public var errorDescription: String? {
        switch self {
        case let .unreadableImage(path):
            "Could not read image at \(path)."
        case let .unsupportedImage(path):
            "Unsupported image format at \(path). Supported formats are JPEG and PNG without interlaced alpha."
        case let .invalidImage(path):
            "Invalid image data at \(path)."
        }
    }
}
