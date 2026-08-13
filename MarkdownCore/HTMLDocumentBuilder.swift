import Foundation

enum HTMLDocumentBuilder {
    static func build(body: String, title: String) -> String {
        """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src cid: data:; style-src 'unsafe-inline'">
          <title>\(HTMLEscaper.text(title))</title>
          <style>
            :root { color-scheme: light dark; }
            * { box-sizing: border-box; }
            body {
              max-width: 920px;
              margin: 0 auto;
              padding: 42px 48px 64px;
              color: CanvasText;
              background: Canvas;
              font: 16px/1.58 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
              overflow-wrap: break-word;
            }
            h1, h2, h3, h4, h5, h6 { line-height: 1.25; margin: 1.4em 0 .55em; }
            h1 { font-size: 2em; padding-bottom: .25em; border-bottom: 1px solid color-mix(in srgb, CanvasText 18%, transparent); }
            h2 { font-size: 1.5em; padding-bottom: .22em; border-bottom: 1px solid color-mix(in srgb, CanvasText 14%, transparent); }
            h3 { font-size: 1.25em; }
            p, ul, ol, blockquote, pre, .table-scroll { margin: 0 0 1em; }
            ul, ol { padding-left: 1.7em; }
            li + li { margin-top: .25em; }
            a { color: LinkText; text-decoration-thickness: .08em; text-underline-offset: .15em; }
            code, pre { font-family: ui-monospace, "SFMono-Regular", Menlo, monospace; }
            code { padding: .12em .34em; border-radius: 5px; background: color-mix(in srgb, CanvasText 9%, transparent); }
            pre { padding: 16px; overflow: auto; border: 1px solid color-mix(in srgb, CanvasText 10%, transparent); border-radius: 9px; background: color-mix(in srgb, CanvasText 6%, transparent); }
            pre code { padding: 0; background: transparent; }
            blockquote { padding: .15em 1em; color: GrayText; border-left: 4px solid color-mix(in srgb, CanvasText 22%, transparent); }
            blockquote > :last-child { margin-bottom: 0; }
            .table-scroll { width: 100%; overflow-x: auto; }
            table { width: 100%; min-width: 620px; border-collapse: collapse; table-layout: fixed; }
            th, td { padding: 8px 10px; vertical-align: top; border: 1px solid color-mix(in srgb, CanvasText 18%, transparent); overflow-wrap: break-word; word-break: normal; }
            th { background: color-mix(in srgb, CanvasText 7%, transparent); font-weight: 600; }
            tr:nth-child(even) td { background: color-mix(in srgb, CanvasText 3%, transparent); }
            table.columns-4 th:nth-child(1), table.columns-4 td:nth-child(1) { width: 11%; }
            table.columns-4 th:nth-child(2), table.columns-4 td:nth-child(2) { width: 24%; }
            table.columns-4 th:nth-child(3), table.columns-4 td:nth-child(3) { width: 31%; }
            table.columns-4 th:nth-child(4), table.columns-4 td:nth-child(4) { width: 34%; }
            table.columns-5 th:nth-child(1), table.columns-5 td:nth-child(1) { width: 14%; }
            table.columns-5 th:nth-child(2), table.columns-5 td:nth-child(2) { width: 22%; }
            table.columns-5 th:nth-child(3), table.columns-5 td:nth-child(3) { width: 12%; }
            table.columns-5 th:nth-child(4), table.columns-5 td:nth-child(4) { width: 16%; }
            table.columns-5 th:nth-child(5), table.columns-5 td:nth-child(5) { width: 36%; }
            table code { white-space: normal; overflow-wrap: anywhere; word-break: break-word; }
            hr { height: 1px; margin: 1.8em 0; border: 0; background: color-mix(in srgb, CanvasText 18%, transparent); }
            img { max-width: 100%; height: auto; border-radius: 7px; }
            .task-list { list-style: none; padding-left: .3em; }
            .task-list input { margin-right: .55em; }
            .image-placeholder { color: GrayText; font-style: italic; }
            @media (max-width: 640px) { body { padding: 24px 26px 44px; } }
            @media print { body { max-width: none; padding: 0; } }
          </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
