# QuickMD Preview

QuickMD renders **Markdown** directly inside Finder’s Quick Look panel.

## Features

- [x] Headings and paragraphs
- [x] **Bold**, *emphasis*, ~~strikethrough~~, and `inline code`
- [x] Links, local images, lists, quotes, tables, and fenced code blocks

> Select this file in Finder and press Space after enabling the extension.

| Feature | Status |
| :--- | ---: |
| Finder preview | Ready |
| Dark Mode | Automatic |

```swift
let preview = MarkdownRenderer().render(markdown)
```
