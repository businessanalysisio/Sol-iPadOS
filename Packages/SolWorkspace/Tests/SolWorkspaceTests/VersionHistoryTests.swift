import XCTest
import SolStore
@testable import SolWorkspace

/// Lịch sử phiên bản (APP-FR-12, O10): danh sách newest-first, khôi phục theo
/// bất biến G2, và lưới an toàn không-mất-chữ khi nội dung hiện tại chưa
/// từng được version hóa.
final class VersionHistoryTests: XCTestCase {
    private var root: URL!
    private var store: DocumentStore!
    private var doc: Document!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-vh-\(UUID().uuidString)", isDirectory: true)
        store = try DocumentStore(root: root, index: SearchIndex())
        doc = try store.createDocument(named: "FRS", contents: "v1")
        try store.versions.record(docID: doc.id, content: "v1", actor: "iPad-A", operation: .edit)
        try store.save(doc, contents: "v2")
        try store.versions.record(docID: doc.id, content: "v2", actor: "iPad-B", operation: .edit)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testListsVersionsNewestFirstWithMetadata() throws {
        let model = VersionHistoryViewModel(store: store, document: doc)
        XCTAssertEqual(model.versions.count, 2)
        XCTAssertEqual(model.versions.first?.actor, "iPad-B")
        XCTAssertEqual(model.versions.last?.actor, "iPad-A")
        XCTAssertEqual(model.content(of: model.versions.last!), "v1")
    }

    func testRestoreWritesContentWithJournalInvariantAndRestoreVersion() throws {
        let model = VersionHistoryViewModel(store: store, document: doc, actor: "iPad-Test")
        let v1 = try XCTUnwrap(model.versions.first { model.content(of: $0) == "v1" })

        XCTAssertTrue(model.restore(v1))

        // File trên đĩa là nội dung đã khôi phục; journal đã hoàn tất chu trình.
        XCTAssertEqual(try store.contents(of: doc), "v1")
        XCTAssertNil(store.journal.pending(docID: doc.id))
        // Version mới nhất là .restore với actor của người khôi phục.
        let newest = try XCTUnwrap(model.versions.first)
        XCTAssertEqual(newest.operation, .restore)
        XCTAssertEqual(newest.actor, "iPad-Test")
        // Nội dung hiện tại ("v2") đã có bản ghi từ trước — không nhân đôi:
        // 2 bản cũ + 1 bản .restore.
        XCTAssertEqual(model.versions.count, 3)
    }

    /// Đang gõ dở (nội dung hiện tại chưa version hóa) mà khôi phục bản cũ →
    /// nội dung dở dang phải được giữ lại thành một version .edit trước.
    func testRestorePreservesUnversionedCurrentContent() throws {
        try store.save(doc, contents: "v3 đang gõ dở") // save không tự ghi version
        let model = VersionHistoryViewModel(store: store, document: doc, actor: "iPad-Test")
        let v1 = try XCTUnwrap(model.versions.first { model.content(of: $0) == "v1" })

        XCTAssertTrue(model.restore(v1))

        XCTAssertEqual(try store.contents(of: doc), "v1")
        // 2 bản cũ + 1 bản .edit (lưới an toàn cho "v3") + 1 bản .restore.
        XCTAssertEqual(model.versions.count, 4)
        let contents = model.versions.compactMap { model.content(of: $0) }
        XCTAssertTrue(contents.contains("v3 đang gõ dở"),
                      "không có đường nào làm mất chữ của người dùng")
        XCTAssertEqual(model.versions.first?.operation, .restore)
    }

    /// Khôi phục về đúng nội dung hiện tại là no-op — không sinh version thừa.
    func testRestoreToIdenticalContentIsNoop() throws {
        let model = VersionHistoryViewModel(store: store, document: doc)
        let v2 = try XCTUnwrap(model.versions.first { model.content(of: $0) == "v2" })
        XCTAssertTrue(model.restore(v2))
        XCTAssertEqual(model.versions.count, 2)
        XCTAssertEqual(try store.contents(of: doc), "v2")
    }
}
