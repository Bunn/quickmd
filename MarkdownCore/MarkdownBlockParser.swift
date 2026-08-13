import Foundation

struct MarkdownBlockParser {
    private let inlineParser: InlineMarkdownParser

    init(resourceResolver: MarkdownResourceResolver) {
        inlineParser = InlineMarkdownParser(resourceResolver: resourceResolver)
    }

    func render(_ source: String) -> String {
        let normalizedSource = source
            .replacing("\r\n", with: "\n")
            .replacing("\r", with: "\n")
        return render(lines: normalizedSource.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))
    }

    private func render(lines: [String]) -> String {
        var output: [String] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            if let fence = fenceMarker(in: trimmed) {
                let language = String(trimmed.dropFirst(fence.count))
                    .trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                index += 1

                while index < lines.count, !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix(fence) {
                    codeLines.append(lines[index])
                    index += 1
                }

                if index < lines.count {
                    index += 1
                }

                let languageAttribute = language.isEmpty
                    ? ""
                    : " class=\"language-\(HTMLEscaper.text(language))\""
                output.append("<pre><code\(languageAttribute)>\(HTMLEscaper.text(codeLines.joined(separator: "\n")))</code></pre>")
                continue
            }

            if let (level, heading) = heading(in: trimmed) {
                output.append("<h\(level)>\(inlineParser.render(heading))</h\(level)>")
                index += 1
                continue
            }

            if isThematicBreak(trimmed) {
                output.append("<hr>")
                index += 1
                continue
            }

            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while index < lines.count {
                    let quoteLine = lines[index].trimmingCharacters(in: .whitespaces)
                    guard quoteLine.hasPrefix(">") else {
                        break
                    }
                    quoteLines.append(String(quoteLine.dropFirst()).trimmingCharacters(in: .whitespaces))
                    index += 1
                }
                output.append("<blockquote>\(render(lines: quoteLines))</blockquote>")
                continue
            }

            if let firstItem = listItem(in: line) {
                let ordered = firstItem.ordered
                var items: [(content: String, checked: Bool?)] = []

                while index < lines.count, let item = listItem(in: lines[index]), item.ordered == ordered {
                    let task = taskItem(in: item.content)
                    items.append((task?.content ?? item.content, task?.checked))
                    index += 1
                }

                let tag = ordered ? "ol" : "ul"
                let hasTasks = items.contains { $0.checked != nil }
                let classAttribute = hasTasks ? " class=\"task-list\"" : ""
                let itemHTML = items.map { item in
                    let checkbox: String
                    if let checked = item.checked {
                        checkbox = checked
                            ? "<input type=\"checkbox\" checked disabled>"
                            : "<input type=\"checkbox\" disabled>"
                    } else {
                        checkbox = ""
                    }
                    return "<li>\(checkbox)\(inlineParser.render(item.content))</li>"
                }.joined(separator: "\n")
                output.append("<\(tag)\(classAttribute)>\n\(itemHTML)\n</\(tag)>")
                continue
            }

            if index + 1 < lines.count,
               let alignments = tableAlignments(from: lines[index + 1]),
               splitTableRow(line).count == alignments.count {
                let headers = splitTableRow(line)
                index += 2
                var rows: [[String]] = []

                while index < lines.count {
                    let cells = splitTableRow(lines[index])
                    guard !lines[index].trimmingCharacters(in: .whitespaces).isEmpty, cells.count == headers.count else {
                        break
                    }
                    rows.append(cells)
                    index += 1
                }

                let headerHTML = zip(headers, alignments).map { header, alignment in
                    "<th style=\"text-align:\(alignment.cssValue)\">\(inlineParser.render(header))</th>"
                }.joined()
                let rowsHTML = rows.map { row in
                    let cells = zip(row, alignments).map { cell, alignment in
                        "<td style=\"text-align:\(alignment.cssValue)\">\(inlineParser.render(cell))</td>"
                    }.joined()
                    return "<tr>\(cells)</tr>"
                }.joined(separator: "\n")
                output.append("<div class=\"table-scroll\"><table class=\"columns-\(headers.count)\"><thead><tr>\(headerHTML)</tr></thead><tbody>\(rowsHTML)</tbody></table></div>")
                continue
            }

            if line.hasPrefix("    ") {
                var codeLines: [String] = []
                while index < lines.count, lines[index].hasPrefix("    ") {
                    codeLines.append(String(lines[index].dropFirst(4)))
                    index += 1
                }
                output.append("<pre><code>\(HTMLEscaper.text(codeLines.joined(separator: "\n")))</code></pre>")
                continue
            }

            var paragraphLines = [trimmingLeadingWhitespace(in: line)]
            index += 1
            while index < lines.count, !startsBlock(at: index, in: lines) {
                paragraphLines.append(trimmingLeadingWhitespace(in: lines[index]))
                index += 1
            }
            output.append("<p>\(inlineParser.render(paragraphLines.joined(separator: "\n")))</p>")
        }

        return output.joined(separator: "\n")
    }

    private func startsBlock(at index: Int, in lines: [String]) -> Bool {
        let line = lines[index]
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || fenceMarker(in: trimmed) != nil || heading(in: trimmed) != nil ||
            isThematicBreak(trimmed) || trimmed.hasPrefix(">") || listItem(in: line) != nil || line.hasPrefix("    ") {
            return true
        }

        return index + 1 < lines.count && tableAlignments(from: lines[index + 1]) != nil
    }

    private func fenceMarker(in line: String) -> String? {
        for markerCharacter in ["`", "~"] {
            let count = line.prefix { String($0) == markerCharacter }.count
            if count >= 3 {
                return String(repeating: markerCharacter, count: count)
            }
        }
        return nil
    }

    private func heading(in line: String) -> (level: Int, content: String)? {
        let level = min(line.prefix { $0 == "#" }.count, 6)
        guard level > 0, line.count > level else {
            return nil
        }

        let contentStart = line.index(line.startIndex, offsetBy: level)
        guard line[contentStart].isWhitespace else {
            return nil
        }

        var content = line[contentStart...].trimmingCharacters(in: .whitespaces)
        while content.hasSuffix("#") {
            content.removeLast()
            content = content.trimmingCharacters(in: .whitespaces)
        }
        return (level, content)
    }

    private func isThematicBreak(_ line: String) -> Bool {
        let compact = line.filter { !$0.isWhitespace }
        guard compact.count >= 3, let first = compact.first, ["*", "-", "_"].contains(first) else {
            return false
        }
        return compact.allSatisfy { $0 == first }
    }

    private func listItem(in line: String) -> (ordered: Bool, content: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let first = trimmed.first, ["-", "+", "*"].contains(first) {
            let contentStart = trimmed.index(after: trimmed.startIndex)
            guard contentStart < trimmed.endIndex, trimmed[contentStart].isWhitespace else {
                return nil
            }
            return (false, String(trimmed[contentStart...]).trimmingCharacters(in: .whitespaces))
        }

        let digits = trimmed.prefix { $0.isNumber }
        guard !digits.isEmpty else {
            return nil
        }
        let markerIndex = trimmed.index(trimmed.startIndex, offsetBy: digits.count)
        guard markerIndex < trimmed.endIndex, trimmed[markerIndex] == "." else {
            return nil
        }
        let contentStart = trimmed.index(after: markerIndex)
        guard contentStart < trimmed.endIndex, trimmed[contentStart].isWhitespace else {
            return nil
        }
        return (true, String(trimmed[contentStart...]).trimmingCharacters(in: .whitespaces))
    }

    private func taskItem(in content: String) -> (content: String, checked: Bool)? {
        guard content.count >= 4, content.hasPrefix("[") else {
            return nil
        }

        let markerEnd = content.index(content.startIndex, offsetBy: 3)
        let marker = content[..<markerEnd].lowercased()
        guard marker == "[ ]" || marker == "[x]" else {
            return nil
        }

        let remainderStart = content.index(after: markerEnd)
        guard remainderStart <= content.endIndex else {
            return nil
        }

        return (
            String(content[remainderStart...]).trimmingCharacters(in: .whitespaces),
            marker == "[x]"
        )
    }

    private func tableAlignments(from line: String) -> [TableAlignment]? {
        let cells = splitTableRow(line)
        guard !cells.isEmpty else {
            return nil
        }

        var alignments: [TableAlignment] = []
        for cell in cells {
            let compact = cell.trimmingCharacters(in: .whitespaces)
            let leadingColon = compact.hasPrefix(":")
            let trailingColon = compact.hasSuffix(":")
            let dashes = compact.trimmingCharacters(in: CharacterSet(charactersIn: ":"))

            guard dashes.count >= 3, dashes.allSatisfy({ $0 == "-" }) else {
                return nil
            }

            if leadingColon && trailingColon {
                alignments.append(.center)
            } else if trailingColon {
                alignments.append(.trailing)
            } else {
                alignments.append(.leading)
            }
        }
        return alignments
    }

    private func splitTableRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") {
            trimmed.removeFirst()
        }
        if trimmed.hasSuffix("|") {
            trimmed.removeLast()
        }

        var cells: [String] = []
        var current = ""
        var isEscaped = false

        for character in trimmed {
            if isEscaped {
                current.append(character)
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
                current.append(character)
            } else if character == "|" {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
        }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }

    private func trimmingLeadingWhitespace(in line: String) -> String {
        String(line.drop(while: { $0 == " " || $0 == "\t" }))
    }
}
