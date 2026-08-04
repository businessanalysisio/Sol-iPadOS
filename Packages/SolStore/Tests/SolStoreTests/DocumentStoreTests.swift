import XCTest
@testable import SolStore

/// M1 gates: APP-FR-01/03/17, APP-AC-08 (purge cascade), APP-BR-02/04.
final class DocumentStoreTests: XCTestCase {
    private var root: URL!
    private var index: SearchIndex!
    private var clock: Date! // mutable fake time for the 30-day purge

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-test-\(UUID().uuidString)", isDirectory: true)
        index = try SearchIndex()
        clock = Date(timeIntervalSince1970: 1_754_000_000)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeStore() throws -> DocumentStore {
        try DocumentStore(root: root, index: index, now: { self.clock })
    }

    // MARK: APP-FR-01 — one call creates an immediately searchable document

    func testCreateIsOneCallAndSearchReady() throws {
        let store = try makeStore()
        let doc = try store.createDocument()
        XCTAssertEqual(doc.title, DocumentStore.untitledName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: doc.url.path))
        XCTAssertEqual(try store.search("tai lieu chua dat ten").map(\.id), [doc.id])
    }

    // MARK: APP-FR-03 — collision suffix, never overwrite

    func testNameCollisionGetsNumericSuffix() throws {
        let store = try makeStore()
        let a = try store.createDocument(named: "Đặc tả", contents: "A")
        let b = try store.createDocument(named: "Đặc tả", contents: "B")
        let c = try store.createDocument(named: "Đặc tả", contents: "C")
        XCTAssertEqual(a.title, "Đặc tả")
        XCTAssertEqual(b.title, "Đặc tả 2")
        XCTAssertEqual(c.title, "Đặc tả 3")
        XCTAssertEqual(try store.contents(of: a), "A") // nothing overwritten
    }

    func testRenameOntoExistingNameSuffixesInsteadOfOverwriting() throws {
        let store = try makeStore()
        _ = try store.createDocument(named: "BRD v2", contents: "giữ nguyên")
        let other = try store.createDocument(named: "Nháp", contents: "x")
        let renamed = try store.rename(other, to: "BRD v2")
        XCTAssertEqual(renamed.title, "BRD v2 2")
    }

    // MARK: APP-BR-02 — file limit with a clear error

    func testOversizeFileThrowsClearError() throws {
        let store = try makeStore()
        let big = String(repeating: "a", count: DocumentStore.maxFileBytes + 1)
        XCTAssertThrowsError(try store.createDocument(named: "To", contents: big)) {
            XCTAssertEqual($0 as? DocumentStoreError, .fileTooLarge(limit: DocumentStore.maxFileBytes))
        }
    }

    // MARK: APP-FR-17 — trash lifecycle

    func testSoftDeleteMovesToTrashAndOutOfSearch() throws {
        let store = try makeStore()
        let doc = try store.createDocument(named: "Biên bản", contents: "workshop ký gửi")
        try store.softDelete(doc)
        XCTAssertEqual(try store.listDocuments(), [])
        XCTAssertEqual(try store.search("bien ban"), [])
        XCTAssertEqual(try store.listTrash().map(\.originalName), ["Biên bản.md"])
    }

    func testRestoreKeepsContentAndReindexes() throws {
        let store = try makeStore()
        let doc = try store.createDocument(named: "Biên bản", contents: "nội dung gốc")
        try store.softDelete(doc)
        let restored = try store.restore(try store.listTrash()[0])
        XCTAssertEqual(try store.contents(of: restored), "nội dung gốc")
        XCTAssertEqual(try store.search("noi dung goc").map(\.id), [restored.id])
    }

    func testRestoreCollisionUsesSuffixRule() throws {
        let store = try makeStore()
        let doc = try store.createDocument(named: "FRS", contents: "cũ")
        try store.softDelete(doc)
        _ = try store.createDocument(named: "FRS", contents: "mới")
        let restored = try store.restore(try store.listTrash()[0])
        XCTAssertEqual(restored.title, "FRS 2")
        XCTAssertEqual(try store.contents(of: restored), "cũ")
    }

    // MARK: APP-AC-08 — purge cascade: content + index gone, not reachable

    func testPurgeCascadesContentAndIndex() throws {
        let store = try makeStore()
        let doc = try store.createDocument(named: "Mật", contents: "dữ liệu nhạy cảm")
        try store.softDelete(doc)
        try store.purge(try store.listTrash()[0])
        XCTAssertEqual(try store.listTrash(), [])
        XCTAssertEqual(try store.search("nhay cam"), [])
        XCTAssertFalse(try index.contains(docID: doc.id))
    }

    // MARK: APP-BR-04 — auto-purge on first open after 30 days

    func testAutoPurgeOnOpenAfterThirtyDays() throws {
        var store = try makeStore()
        let doc = try store.createDocument(named: "Sắp hết hạn", contents: "x")
        try store.softDelete(doc)
        XCTAssertEqual(try store.listTrash().count, 1)

        clock = clock.addingTimeInterval(31 * 24 * 3600) // 31 days pass
        store = try makeStore()                           // "first open after 30 days"
        XCTAssertEqual(try store.listTrash(), [])
        XCTAssertFalse(try index.contains(docID: doc.id))
    }

    func testItemsYoungerThanThirtyDaysSurviveReopen() throws {
        var store = try makeStore()
        let doc = try store.createDocument(named: "Còn hạn", contents: "x")
        try store.softDelete(doc)
        clock = clock.addingTimeInterval(29 * 24 * 3600)
        store = try makeStore()
        XCTAssertEqual(try store.listTrash().count, 1)
        _ = store
    }

    // MARK: Files created outside the app are adopted (iCloud/Files.app)

    func testExternallyCreatedFileIsAdoptedAndIndexed() throws {
        let store = try makeStore()
        let alien = root.appendingPathComponent("Từ Files.md")
        try "nội dung bên ngoài".write(to: alien, atomically: true, encoding: .utf8)
        let docs = try store.listDocuments()
        XCTAssertEqual(docs.map(\.title), ["Từ Files"])
        XCTAssertEqual(try store.search("ben ngoai").map(\.title), ["Từ Files"])
    }
}
