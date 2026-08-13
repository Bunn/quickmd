import Foundation

enum PreviewError: LocalizedError {
    case fileTooLarge

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            "This Markdown file is too large to preview safely."
        }
    }
}
