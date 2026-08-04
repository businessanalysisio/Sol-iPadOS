import XCTest
@testable import SolStore

/// M4 Layer-1 gates (ADR-A03): conflicted-copy logic is deterministic and
/// fully specified — naming (APP-BR-03), no-merge (ADR-A02), preservation
/// ("mọi phiên bản phát hiện được đều được bảo toàn"), badge + audit trail.
final class ConflictResolverTests: XCTestCase {
    private var root: URL!
    private var store: DocumentStore!
    private var resolver: ConflictResolver!
    private let conflictDate = Date(timeIntervalSince1970: 1_754_000_000) // 2025-07-31 UTC

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-cr-\(UUID().uuidString)", isDirectory: true)
        store = try DocumentStore(root: root, index: SearchIndex())
        resolver = ConflictResolver(store: store)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeConflict(content: String = "bản của Hảo") -> ConflictingVersion {
        ConflictingVersion(actorName: "Hảo", modifiedAt: conflictDate, content: content)
    }

    // MARK: APP-BR-03 — exact name format, ISO date, EN keyword cross-locale

    func testCopyNameFormatExact() throws {
        let original = try store.createDocument(named: "FRS-Quy-trinh-Bao-gia", contents: "bản của tôi")
        let event = try resolver.resolve(original: original, conflicting: makeConflict())
        XCTAssertEqual(event.copy.title, "FRS-Quy-trinh-Bao-gia (conflicted copy Hảo 2025-07-31)")
        XCTAssertEqual(event.copy.url.lastPathComponent,
                       "FRS-Quy-trinh-Bao-gia (conflicted copy Hảo 2025-07-31).md")
    }

    func testRepeatConflictSameDayGetsNumericSuffix() throws {
        let original = try store.createDocument(named: "FRS", contents: "gốc")
        _ = try resolver.resolve(original: original, conflicting: makeConflict(content: "lần 1"))
        let second = try resolver.resolve(original: original, conflicting: makeConflict(content: "lần 2"))
        XCTAssertEqual(second.copy.title, "FRS (conflicted copy Hảo 2025-07-31) 2")
    }

    // MARK: ADR-A02 — no merge, no winner; both versions byte-exact

    func testBothVersionsPreservedByteExact() throws {
        let original = try store.createDocument(named: "FRS", contents: "bản của tôi\ndòng hai")
        let event = try resolver.resolve(
            original: original,
            conflicting: makeConflict(content: "bản của Hảo\ndòng khác hẳn"))

        XCTAssertEqual(try store.contents(of: event.original), "bản của tôi\ndòng hai")
        XCTAssertEqual(try store.contents(of: event.copy), "bản của Hảo\ndòng khác hẳn")
    }

    // MARK: M-01 — copy is badged, searchable, grouped after originals

    func testCopyIsBadgedAndSearchable() throws {
        let original = try store.createDocument(named: "FRS", contents: "báo giá ưu đãi")
        let event = try resolver.resolve(original: original, conflicting: makeConflict(content: "báo giá bản Hảo"))

        XCTAssertTrue(event.copy.isConflictCopy)
        XCTAssertFalse(event.original.isConflictCopy)

        let hits = try store.search("bao gia")
        XCTAssertEqual(hits.count, 2) // both indexed — G2 over search tidiness
        // Grouping: originals first, copies after (WorkspaceView badges them).
        XCTAssertFalse(hits[0].isConflictCopy)
        XCTAssertTrue(hits[1].isConflictCopy)
    }

    // MARK: APP-FR-12 — audit trail on the original

    func testConflictRecordsVersionWithActorAndOperation() throws {
        let original = try store.createDocument(named: "FRS", contents: "gốc")
        _ = try resolver.resolve(original: original, conflicting: makeConflict())

        let versions = try store.versions.list(docID: original.id)
        XCTAssertEqual(versions.first?.operation, .conflictCopy)
        XCTAssertEqual(versions.first?.actor, "Hảo")
        XCTAssertEqual(try store.versions.content(of: versions.first!), "bản của Hảo")
    }

    // MARK: Banner contract (design.md §6: banner must name the copy file)

    func testEventCarriesEverythingTheBannerNeeds() throws {
        let original = try store.createDocument(named: "FRS", contents: "gốc")
        let event = try resolver.resolve(original: original, conflicting: makeConflict())
        XCTAssertEqual(event.actorName, "Hảo")
        XCTAssertTrue(event.copy.title.contains("conflicted copy"))
        XCTAssertEqual(event.original.id, original.id)
    }
}

/// Chip 3 trạng thái — M4 unlock (M-02 phase policy ends here).
final class SyncChipTests: XCTestCase {
    func testManualEngineDrivesAllThreeChipStates() {
        let engine = ManualSyncEngine(status: .upToDate)
        var seen: [SyncStatus] = []
        engine.onStatusChange = { seen.append($0) }
        engine.set(.syncing(pending: 3))
        engine.set(.offline)
        engine.set(.upToDate)
        XCTAssertEqual(seen, [.syncing(pending: 3), .offline, .upToDate])
    }
}
