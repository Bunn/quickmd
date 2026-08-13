import XCTest
@testable import MarkdownCore

final class MarkdownRendererTests: XCTestCase {
    func testRendersCommonBlocksAndInlineFormatting() {
        let source = """
        # Heading

        A **bold** word, an *emphasized* word, and `code`.

        - First
        - Second

        > A quote
        """

        let html = MarkdownRenderer().render(source).html

        XCTAssertTrue(html.contains("<h1>Heading</h1>"))
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
        XCTAssertTrue(html.contains("<em>emphasized</em>"))
        XCTAssertTrue(html.contains("<code>code</code>"))
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<blockquote>"))
    }

    func testRendersTablesAndTaskLists() {
        let source = """
        | Name | State |
        | :--- | ---: |
        | Build | Done |

        - [x] Render Markdown
        - [ ] Ship app
        """

        let html = MarkdownRenderer().render(source).html

        XCTAssertTrue(html.contains("<table class="))
        XCTAssertTrue(html.contains("<div class=\"table-scroll\">"))
        XCTAssertTrue(html.contains("<table class=\"columns-2\">"))
        XCTAssertTrue(html.contains("text-align:left"))
        XCTAssertTrue(html.contains("text-align:right"))
        XCTAssertTrue(html.contains("type=\"checkbox\" checked disabled"))
    }

    func testEscapesRawHTMLAndRejectsUnsafeLinks() {
        let source = "<script>alert('no')</script> [bad](javascript:alert(1))"

        let html = MarkdownRenderer().render(source).html

        XCTAssertFalse(html.contains("<script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
        XCTAssertFalse(html.contains("javascript:"))
    }

    func testMapsRelativeImagesToQuickLookAttachments() {
        let baseURL = URL(fileURLWithPath: "/tmp/notes", isDirectory: true)
        let document = MarkdownRenderer().render(
            "![Diagram](images/diagram.png)",
            baseURL: baseURL
        )

        XCTAssertTrue(document.html.contains("src=\"cid:image-1\""))
        XCTAssertEqual(document.resources["image-1"]?.path, "/tmp/notes/images/diagram.png")
    }

    func testRendersBothKindsOfHardLineBreak() {
        let source = "First line  \nSecond line\\\nThird line"

        let html = MarkdownRenderer().render(source).html

        XCTAssertTrue(html.contains("First line<br>\nSecond line<br>\nThird line"))
    }

    func testRendersSafeHTMLBreaksInsideTableCells() {
        let source = """
        | Scope | Details | State | Events |
        |---|---|---|---|
        | S1 | Question<br>Dashboard row | Partial | `a_very_long_event_identifier_that_must_wrap` |
        """

        let html = MarkdownRenderer().render(source).html

        XCTAssertTrue(html.contains("<table class=\"columns-4\">"))
        XCTAssertTrue(html.contains("Question<br>Dashboard row"))
        XCTAssertFalse(html.contains("&lt;br&gt;"))
    }
}
