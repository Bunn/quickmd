import Foundation

public struct MarkdownRenderer: Sendable {
    public init() {}

    public func render(
        _ source: String,
        baseURL: URL? = nil,
        title: String = "Markdown Preview"
    ) -> MarkdownDocument {
        let resolver = MarkdownResourceResolver(baseURL: baseURL)
        let blockParser = MarkdownBlockParser(resourceResolver: resolver)
        let body = blockParser.render(source)
        let html = HTMLDocumentBuilder.build(body: body, title: title)

        return MarkdownDocument(html: html, resources: resolver.resources)
    }
}
