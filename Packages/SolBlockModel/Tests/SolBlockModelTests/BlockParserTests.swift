import XCTest
@testable import SolBlockModel

final class BlockParserTests: XCTestCase {

    // MARK: Line tags (gutter vocabulary — mockup v2 / design.md §6)

    func testLineTagsMatchMockupVocabulary() {
        let doc = """
        # FRS · Quy trình Báo giá
        Phiên bản 1.2

        ## US-12 · Tạo báo giá
        **Là** nhân viên Sales

        | ID | Tiêu chí |
        |----|----------|
        | AC1 | Kế thừa giá |

        > SLA: **4 giờ làm việc**
        - Chiết khấu >10% cần duyệt
        - Log lý do từ chối
        """
        let types = BlockParser.parse(doc).lineTypes.map(\.rawValue)
        XCTAssertEqual(types, ["H1", "P", "·", "H2", "P", "·",
                               "TB", "TB", "TB", "·", "BQ", "UL", "UL"])
    }

    func testFencedBlockTagsEveryLineIncludingBody() {
        let doc = """
        ```sol-data type=bar
        week,count
        W1,120
        ```
        sau fence
        """
        let r = BlockParser.parse(doc)
        XCTAssertEqual(r.lineTypes.map(\.rawValue), ["DB", "DB", "DB", "DB", "P"])
        XCTAssertEqual(r.blocks.first, .fence(info: "sol-data type=bar", body: ["week,count", "W1,120"]))
    }

    func testUnclosedFenceConsumesToEndWithoutCrashing() {
        let r = BlockParser.parse("```\nchưa đóng")
        XCTAssertEqual(r.lineTypes, [.fence, .fence])
        XCTAssertEqual(r.blocks, [.fence(info: "", body: ["chưa đóng"])])
    }

    // MARK: Preview tree

    func testTableSeparatorRowIsTaggedButNotRendered() {
        let r = BlockParser.parse("| A | B |\n|---|---|\n| 1 | 2 |")
        guard case let .table(header, rows) = r.blocks[0] else { return XCTFail("expected table") }
        XCTAssertEqual(header, [[.text("A")], [.text("B")]])
        XCTAssertEqual(rows, [[[.text("1")], [.text("2")]]])
        XCTAssertEqual(r.lineTypes, [.table, .table, .table]) // gutter still tags all 3
    }

    func testConsecutiveListLinesMergeIntoOneBlock() {
        let r = BlockParser.parse("- một\n- hai\n- ba")
        XCTAssertEqual(r.blocks.count, 1)
        guard case let .list(items) = r.blocks[0] else { return XCTFail("expected list") }
        XCTAssertEqual(items.count, 3)
    }

    func testInlineParsing() {
        XCTAssertEqual(InlineParser.parse("**Là** nhân viên *Sales* dùng `sol-data`"),
                       [.bold("Là"), .text(" nhân viên "), .italic("Sales"),
                        .text(" dùng "), .code("sol-data")])
        // Unterminated markers stay literal — no swallowed text.
        XCTAssertEqual(InlineParser.parse("a ** b"), [.text("a ** b")])
        XCTAssertEqual(InlineParser.parse("100 * 2 = 200"), [.text("100 * 2 = 200")])
    }

    // MARK: APP-FR-07 — gutter is product truth (structural invariant)

    func testEveryLineGetsExactlyOneTag() {
        let docs = [
            "# a\n\n## b\n- c\n| d |\n> e\n```\nf\n```\ng",
            "", "\n\n\n", "chỉ một đoạn văn",
        ]
        for doc in docs {
            let lines = doc.components(separatedBy: "\n")
            XCTAssertEqual(BlockParser.parse(doc).lineTypes.count, lines.count,
                           "tag count must equal line count for: \(doc.debugDescription)")
        }
    }

    // MARK: BlockDocument tag-diff (gutter redraw scope)

    func testDiffRangeConfinesSingleLineEdit() {
        let doc = BlockDocument(text: "# tiêu đề\nđoạn một\nđoạn hai\n- item")
        doc.replaceAll(with: "# tiêu đề\nđoạn một đã sửa\nđoạn hai\n- item")
        XCTAssertTrue(doc.changedLines.isEmpty) // tag unchanged (P→P): nothing to redraw
        doc.replaceAll(with: "# tiêu đề\n## đoạn một đã sửa\nđoạn hai\n- item")
        XCTAssertEqual(doc.changedLines, 1..<2) // P→H2: exactly one gutter line
    }
}
