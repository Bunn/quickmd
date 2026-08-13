import Foundation

final class MarkdownResourceResolver {
    private let baseURL: URL?
    private var identifiersByURL: [URL: String] = [:]
    private var nextIdentifier = 1

    private(set) var resources: [String: URL] = [:]

    init(baseURL: URL?) {
        self.baseURL = baseURL
    }

    func resolveImage(_ destination: String) -> String? {
        let cleanedDestination = destination
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "<>"))

        guard !cleanedDestination.isEmpty else {
            return nil
        }

        let resourceURL: URL?
        if let parsedURL = URL(string: cleanedDestination), parsedURL.scheme != nil {
            resourceURL = parsedURL.isFileURL ? parsedURL : nil
        } else if let baseURL {
            resourceURL = URL(
                fileURLWithPath: cleanedDestination.removingPercentEncoding ?? cleanedDestination,
                relativeTo: baseURL
            ).standardizedFileURL
        } else {
            resourceURL = nil
        }

        guard let resourceURL else {
            return nil
        }

        if let identifier = identifiersByURL[resourceURL] {
            return identifier
        }

        let identifier = "image-\(nextIdentifier)"
        nextIdentifier += 1
        identifiersByURL[resourceURL] = identifier
        resources[identifier] = resourceURL
        return identifier
    }
}
