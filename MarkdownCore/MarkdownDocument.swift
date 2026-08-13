import Foundation

public struct MarkdownDocument: Sendable {
    public let html: String
    public let resources: [String: URL]

    init(html: String, resources: [String: URL]) {
        self.html = html
        self.resources = resources
    }
}
