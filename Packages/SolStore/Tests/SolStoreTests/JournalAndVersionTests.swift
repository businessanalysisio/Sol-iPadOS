import XCTest
@testable import SolStore

/// M2 gates: kill-app recovery (G2), version metadata floor (DAVID-01),
/// full purge cascade (APP-AC-08 now includes journal + versions).
final class JournalAndVersionTests: XCTestCase {
    private var root: URL!
    private var clock: Date!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-jv-\(UUID().uuidString)", isDirectory: true)
        clock = Date(timeIntervalSince1970: 1_754_000_000)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeStore() throws -> DocumentStore {
        try DocumentStore(root: root, index: SearchIndex(), now: { self.clock })
    }

    // MARK: "Kill app giữa lúc gõ → mở lại không mất ký tự"

    func testCrashMidEditRecoversFromJournal() throws {
        // Session 1: user types; journal records pending BEFORE any save.
        let store1 = try makeStore()
        let doc = try store1.createDocument(named: "FRS", contents: "bản đã lưu")
        try store1.journal.recordPending(docID: doc.id, content: "bản đã lưu + ký tự chưa kịp save")
        // App dies here — no save(), no clearPending().

        // Session 2: a fresh store on the same root sees the pending journal.
        let store2 = try makeStore()
        XCTAssertEqual(store2.journal.pending(docID: doc.id),
                       "bản đã lưu + ký tự chưa kịp save")
        // The main file still holds the last clean save — nothing corrupted.
        XCTAssertEqual(try store2.contents(of: doc), "bản đã lưu")
    }

    func testCleanSaveClearsJournal() throws {
        let store = try makeStore()
        let doc = try store.createDocument(named: "FRS", contents: "v1")
        try store.journal.recordPending(docID: doc.id, content: "v2 đang gõ")
        try store.save(doc, contents: "v2 đang gõ")
        store.journal.clearPending(docID: doc.id)
        XCTAssertNil(store.journal.pending(docID: doc.id))
    }

    // MARK: Version metadata floor — actor / timestamp / operation

    func testVersionsCarryActorTimestampOperation() throws {
        let store = try makeStore()
        let doc = try store.createDocument(named: "FRS", contents: "v1")
        try store.versions.record(docID: doc.id, content: "v1", actor: "iPad của Sol", operation: .edit)
        clock = clock.addingTimeInterval(60)
        try store.versions.record(docID: doc.id, content: "v2", actor: "iPad của Sol", operation: .edit)

        let versions = try store.versions.list(docID: doc.id)
        XCTAssertEqual(versions.count, 2)
        XCTAssertEqual(versions[0].operation, .edit)
        XCTAssertEqual(versions[0].actor, "iPad của Sol")
        XCTAssertGreaterThan(versions[0].timestamp, versions[1].timestamp) // newest first
        XCTAssertEqual(try store.versions.content(of: versions[1]), "v1")
    }

    // MARK: Xuất snapshot (Phụ lục A)

    func testExportSnapshotWritesReadOnlyCopyAndVersion() throws {
        let store = try makeStore()
        let doc = try store.createDocument(named: "Đặc tả", contents: "nội dung")
        let url = try store.exportSnapshot(of: doc, actor: "iPad của Sol")

        // Expected stamp derives from the injected clock — same formatter as
        // the store (never hardcode a year: the first version of this test
        // assumed 2026 while the fake epoch is 2025).
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        XCTAssertEqual(url.lastPathComponent, "Đặc tả-snapshot-\(f.string(from: clock)).md")
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "nội dung")
        XCTAssertEqual(try store.versions.list(docID: doc.id).first?.operation, .snapshot)
    }

    // MARK: APP-AC-08 — the cascade now covers all four stores

    func testPurgeCascadesJournalAndVersionsToo() throws {
        let store = try makeStore()
        let doc = try store.createDocument(named: "Mật", contents: "nhạy cảm")
        try store.journal.recordPending(docID: doc.id, content: "nhạy cảm hơn")
        try store.versions.record(docID: doc.id, content: "nhạy cảm", actor: "a", operation: .edit)
        try store.softDelete(doc)
        try store.purge(try store.listTrash()[0])

        XCTAssertNil(store.journal.pending(docID: doc.id))
        XCTAssertEqual(try store.versions.list(docID: doc.id), [])
        XCTAssertEqual(try store.search("nhay cam"), [])
    }
}
