import XCTest
import SolStore
@testable import SolEditor

final class EditorViewModelTests: XCTestCase {
    private var root: URL!
    private var store: DocumentStore!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-ed-\(UUID().uuidString)", isDirectory: true)
        store = try DocumentStore(root: root, index: SearchIndex())
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeModel(contents: String = "# FRS\nnội dung") throws -> (EditorViewModel, Document) {
        let doc = try store.createDocument(named: "FRS", contents: contents)
        let model = try EditorViewModel(store: store, document: doc, actor: "test")
        return (model, doc)
    }

    // MARK: Save pipeline (deterministic via flush — no sleeps)

    func testEditThenFlushSavesJournalsAndVersions() throws {
        let (model, doc) = try makeModel()
        model.setText("# FRS\nnội dung mới")
        XCTAssertEqual(model.saveState, .journaled) // chip: "Chưa lưu — journal ghi nhận"

        model.flush()
        XCTAssertEqual(model.saveState, .saved)
        XCTAssertEqual(try store.contents(of: doc), "# FRS\nnội dung mới")
        XCTAssertNil(store.journal.pending(docID: doc.id))
        let versions = try store.versions.list(docID: doc.id)
        XCTAssertEqual(versions.first?.operation, .edit)
        XCTAssertEqual(versions.first?.actor, "test")
    }

    // MARK: Crash recovery — journal wins over stale file (G2)

    func testInitRecoversPendingJournal() throws {
        let doc = try store.createDocument(named: "FRS", contents: "bản cũ")
        try store.journal.recordPending(docID: doc.id, content: "bản cũ + gõ dở")
        let model = try EditorViewModel(store: store, document: doc, actor: "test")
        XCTAssertEqual(model.text, "bản cũ + gõ dở")
        XCTAssertEqual(model.saveState, .journaled) // honest: recovered ≠ saved
    }

    func testInitWithCleanJournalUsesFile() throws {
        let (model, _) = try makeModel(contents: "sạch")
        XCTAssertEqual(model.text, "sạch")
        XCTAssertEqual(model.saveState, .saved)
    }

    // MARK: Toolbar ops — APP-FR-08

    func testWrapSelectionBold() throws {
        let (model, _) = try makeModel(contents: "chọn đoạn này")
        model.wrapSelection(NSRange(location: 0, length: 4), with: "**")
        XCTAssertEqual(model.text, "**chọn** đoạn này")
    }

    func testPrefixCurrentLineHeading() throws {
        let (model, _) = try makeModel(contents: "dòng một\ndòng hai")
        let secondLine = ("dòng một\nd" as NSString).length - 1
        model.prefixCurrentLine(NSRange(location: secondLine, length: 0), with: "## ")
        XCTAssertEqual(model.text, "dòng một\n## dòng hai")
    }

    func testInsertTableAppendsAndReparses() throws {
        let (model, _) = try makeModel(contents: "x")
        model.insertTable()
        XCTAssertTrue(model.text.contains("| Cột A | Cột B | Cột C |"))
        XCTAssertTrue(model.blockDoc.result.lineTypes.contains(.table)) // gutter sees it same frame
    }

    // MARK: Gutter ↔ preview consistency surfaced at the VM level (APP-FR-07)

    func testLineTypesAlwaysMatchLineCount() throws {
        let (model, _) = try makeModel()
        for text in ["", "# a", "a\n\nb", "```\nx\n```", "| a |\n|---|\n| 1 |"] {
            model.setText(text)
            XCTAssertEqual(model.blockDoc.result.lineTypes.count,
                           text.components(separatedBy: "\n").count)
        }
    }
}
