import Foundation

struct InlineMarkdownParser {
    let resourceResolver: MarkdownResourceResolver

    func render(_ source: String) -> String {
        render(source[...])
    }

    private func render(_ source: Substring) -> String {
        var output = ""
        var index = source.startIndex

        while index < source.endIndex {
            if source[index...].hasPrefix("\\"), let next = nextIndex(after: index, in: source) {
                if source[next].isNewline {
                    output += "<br>\n"
                    index = source.index(after: next)
                    continue
                }

                output += HTMLEscaper.text(String(source[next]))
                index = source.index(after: next)
                continue
            }

            if source[index...].hasPrefix("`"),
               let (html, nextIndex) = renderCodeSpan(at: index, in: source) {
                output += html
                index = nextIndex
                continue
            }

            if source[index...].hasPrefix("!["),
               let (html, nextIndex) = renderImage(at: index, in: source) {
                output += html
                index = nextIndex
                continue
            }

            if source[index...].hasPrefix("["),
               let (html, nextIndex) = renderLink(at: index, in: source) {
                output += html
                index = nextIndex
                continue
            }

            if source[index...].hasPrefix("<"),
               let (html, nextIndex) = renderSafeLineBreak(at: index, in: source) {
                output += html
                index = nextIndex
                continue
            }

            if source[index...].hasPrefix("<"),
               let (html, nextIndex) = renderAutolink(at: index, in: source) {
                output += html
                index = nextIndex
                continue
            }

            let emphasisMarkers = [
                ("**", "strong"),
                ("__", "strong"),
                ("~~", "del"),
                ("*", "em"),
                ("_", "em")
            ]

            var renderedEmphasis = false
            for (marker, tag) in emphasisMarkers where source[index...].hasPrefix(marker) {
                if let (html, nextIndex) = renderDelimited(
                    marker: marker,
                    tag: tag,
                    at: index,
                    in: source
                ) {
                    output += html
                    index = nextIndex
                    renderedEmphasis = true
                    break
                }
            }

            if renderedEmphasis {
                continue
            }

            if source[index].isNewline {
                let hardBreak = hasHardBreak(before: index, in: source)
                if hardBreak {
                    while output.last == " " {
                        output.removeLast()
                    }
                    output += "<br>\n"
                } else {
                    output += "\n"
                }
                index = source.index(after: index)
                continue
            }

            output += HTMLEscaper.text(String(source[index]))
            index = source.index(after: index)
        }

        return output
    }

    private func renderCodeSpan(
        at start: Substring.Index,
        in source: Substring
    ) -> (String, Substring.Index)? {
        var markerEnd = start
        while markerEnd < source.endIndex, source[markerEnd] == "`" {
            markerEnd = source.index(after: markerEnd)
        }

        let marker = String(source[start..<markerEnd])
        guard let closingRange = source.range(of: marker, range: markerEnd..<source.endIndex) else {
            return nil
        }

        var code = String(source[markerEnd..<closingRange.lowerBound])
        code = code.replacing("\n", with: " ")
        if code.hasPrefix(" "), code.hasSuffix(" "), code.trimmingCharacters(in: .whitespaces).isEmpty == false {
            code.removeFirst()
            code.removeLast()
        }

        return (
            "<code>\(HTMLEscaper.text(code))</code>",
            closingRange.upperBound
        )
    }

    private func renderImage(
        at start: Substring.Index,
        in source: Substring
    ) -> (String, Substring.Index)? {
        let labelStart = source.index(start, offsetBy: 2)
        guard
            let separatorRange = source.range(of: "](", range: labelStart..<source.endIndex),
            let closing = source[separatorRange.upperBound...].firstIndex(of: ")")
        else {
            return nil
        }

        let alt = String(source[labelStart..<separatorRange.lowerBound])
        let rawDestination = String(source[separatorRange.upperBound..<closing])
        let destination = linkDestination(from: rawDestination)
        let nextIndex = source.index(after: closing)

        guard let identifier = resourceResolver.resolveImage(destination) else {
            return (
                "<span class=\"image-placeholder\">Image: \(HTMLEscaper.text(alt))</span>",
                nextIndex
            )
        }

        return (
            "<img src=\"cid:\(HTMLEscaper.text(identifier))\" alt=\"\(HTMLEscaper.text(alt))\">",
            nextIndex
        )
    }

    private func renderLink(
        at start: Substring.Index,
        in source: Substring
    ) -> (String, Substring.Index)? {
        let labelStart = source.index(after: start)
        guard
            let separatorRange = source.range(of: "](", range: labelStart..<source.endIndex),
            let closing = source[separatorRange.upperBound...].firstIndex(of: ")")
        else {
            return nil
        }

        let label = source[labelStart..<separatorRange.lowerBound]
        let rawDestination = String(source[separatorRange.upperBound..<closing])
        let destination = linkDestination(from: rawDestination)
        let nextIndex = source.index(after: closing)

        guard let safeDestination = safeLink(destination) else {
            return (render(label), nextIndex)
        }

        return (
            "<a href=\"\(HTMLEscaper.text(safeDestination))\">\(render(label))</a>",
            nextIndex
        )
    }

    private func renderAutolink(
        at start: Substring.Index,
        in source: Substring
    ) -> (String, Substring.Index)? {
        let contentStart = source.index(after: start)
        guard let closing = source[contentStart...].firstIndex(of: ">") else {
            return nil
        }

        let value = String(source[contentStart..<closing])
        let destination: String
        if value.contains("@"), !value.contains(":") {
            destination = "mailto:\(value)"
        } else {
            destination = value
        }

        guard let safeDestination = safeLink(destination) else {
            return nil
        }

        return (
            "<a href=\"\(HTMLEscaper.text(safeDestination))\">\(HTMLEscaper.text(value))</a>",
            source.index(after: closing)
        )
    }

    private func renderSafeLineBreak(
        at start: Substring.Index,
        in source: Substring
    ) -> (String, Substring.Index)? {
        for tag in ["<br>", "<br/>", "<br />"] {
            guard let end = source.index(start, offsetBy: tag.count, limitedBy: source.endIndex) else {
                continue
            }

            if source[start..<end].lowercased() == tag {
                return ("<br>", end)
            }
        }

        return nil
    }

    private func renderDelimited(
        marker: String,
        tag: String,
        at start: Substring.Index,
        in source: Substring
    ) -> (String, Substring.Index)? {
        let contentStart = source.index(start, offsetBy: marker.count)
        guard
            contentStart < source.endIndex,
            let closingRange = source.range(of: marker, range: contentStart..<source.endIndex),
            closingRange.lowerBound > contentStart
        else {
            return nil
        }

        let content = source[contentStart..<closingRange.lowerBound]
        return ("<\(tag)>\(render(content))</\(tag)>", closingRange.upperBound)
    }

    private func linkDestination(from rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("<"), let closing = trimmed.firstIndex(of: ">") {
            return String(trimmed[trimmed.index(after: trimmed.startIndex)..<closing])
        }

        if let whitespace = trimmed.firstIndex(where: { $0.isWhitespace }) {
            return String(trimmed[..<whitespace])
        }

        return trimmed
    }

    private func safeLink(_ destination: String) -> String? {
        if destination.hasPrefix("#") {
            return destination
        }

        guard let url = URL(string: destination), let scheme = url.scheme?.lowercased() else {
            return nil
        }

        return ["http", "https", "mailto"].contains(scheme) ? destination : nil
    }

    private func hasHardBreak(before index: Substring.Index, in source: Substring) -> Bool {
        guard index > source.startIndex else {
            return false
        }

        let previous = source.index(before: index)
        if source[previous] == "\\" {
            return true
        }

        guard source[previous] == " ", previous > source.startIndex else {
            return false
        }

        return source[source.index(before: previous)] == " "
    }

    private func nextIndex(
        after index: Substring.Index,
        in source: Substring
    ) -> Substring.Index? {
        let next = source.index(after: index)
        return next < source.endIndex ? next : nil
    }
}
