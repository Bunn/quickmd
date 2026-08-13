import MarkdownCore
import QuickLookUI
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private let maximumSourceSize = 10 * 1_024 * 1_024
    private let maximumAttachmentSize = 20 * 1_024 * 1_024

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let sourceData = try Data(contentsOf: request.fileURL, options: .mappedIfSafe)
        guard sourceData.count <= maximumSourceSize else {
            throw PreviewError.fileTooLarge
        }

        let source = String(decoding: sourceData, as: UTF8.self)
        let renderer = MarkdownRenderer()
        let document = renderer.render(
            source,
            baseURL: request.fileURL.deletingLastPathComponent(),
            title: request.fileURL.lastPathComponent
        )

        return QLPreviewReply(
            dataOfContentType: .html,
            contentSize: CGSize(width: 900, height: 700)
        ) { [maximumAttachmentSize] reply in
            reply.title = request.fileURL.deletingPathExtension().lastPathComponent
            reply.attachments = Self.loadAttachments(
                from: document.resources,
                maximumSize: maximumAttachmentSize
            )
            return Data(document.html.utf8)
        }
    }

    private static func loadAttachments(
        from resources: [String: URL],
        maximumSize: Int
    ) -> [String: QLPreviewReplyAttachment] {
        var attachments: [String: QLPreviewReplyAttachment] = [:]

        for (identifier, url) in resources {
            guard
                let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
                let fileSize = values.fileSize,
                fileSize <= maximumSize,
                let contentType = UTType(filenameExtension: url.pathExtension),
                contentType.conforms(to: .image),
                let data = try? Data(contentsOf: url, options: .mappedIfSafe)
            else {
                continue
            }

            attachments[identifier] = QLPreviewReplyAttachment(
                data: data,
                contentType: contentType
            )
        }

        return attachments
    }
}
