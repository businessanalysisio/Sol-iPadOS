import XCTest
import SolStore
import SolBlockModel
import SolDataBlocks
@testable import SolWorkspace

/// Seed "BA Bootcamp" (SOL Bootcamp OS) — install-once semantics + the seed
/// content itself must survive the real parse pipeline, not just look right.
final class BootcampSeedTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-seed-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeStore() throws -> DocumentStore {
        try DocumentStore(root: root, index: SearchIndex())
    }

    func testInstallsOnceOnFreshWorkspace() throws {
        let store = try makeStore()
        XCTAssertTrue(try BootcampSeed.installIfNeeded(into: store))

        let titles = try store.listDocuments().map(\.title).sorted()
        XCTAssertEqual(titles, [
            "BA Bootcamp — 00 · Read Me",
            "BA Bootcamp — 01 · Backlog",
            "BA Bootcamp — 02 · Sprint Plan",
            "BA Bootcamp — 03 · Dashboard",
        ])

        // Second call is a no-op — no duplicates.
        XCTAssertFalse(try BootcampSeed.installIfNeeded(into: store))
        XCTAssertEqual(try store.listDocuments().count, 4)
    }

    /// User intent wins: deleting a seed document must not resurrect it on
    /// the next launch (marker outlives the documents).
    func testDeletedSeedStaysDeletedAcrossRelaunch() throws {
        let store = try makeStore()
        _ = try BootcampSeed.installIfNeeded(into: store)
        let backlog = try XCTUnwrap(try store.listDocuments()
            .first { $0.title.contains("Backlog") })
        try store.softDelete(backlog)

        // Relaunch = a fresh store over the same root, bootstrap re-runs seeding.
        let reopened = try makeStore()
        XCTAssertFalse(try BootcampSeed.installIfNeeded(into: reopened))
        XCTAssertEqual(try reopened.listDocuments().count, 3)
    }

    /// Seeded docs go through createDocument → they are searchable via FTS,
    /// including the đ/Đ fold path (APP-FR-04 / Phụ lục C).
    func testSeedContentIsIndexedForSearch() throws {
        let store = try makeStore()
        _ = try BootcampSeed.installIfNeeded(into: store)
        XCTAssertFalse(try store.search("capstone").isEmpty)
        XCTAssertFalse(try store.search("MoSCoW").isEmpty)
    }

    /// Every sol-data fence in the seed set must parse into a render-ready
    /// spec — a seed doc that shows a CSV error banner is a shipping bug.
    func testAllSeedDataBlocksParse() throws {
        var fences = 0
        for doc in BootcampSeed.documents {
            for case let .fence(info, body) in BlockParser.parse(doc.body).blocks
            where DataBlockParser.isSolData(info: info) {
                fences += 1
                switch DataBlockParser.parse(info: info, body: body) {
                case .success(let spec):
                    XCTAssertFalse(spec.points.isEmpty,
                                   "\(doc.name): fence “\(info)” has no data points")
                case .failure(let error):
                    XCTFail("\(doc.name): fence “\(info)” — \(error.message)")
                }
            }
        }
        XCTAssertEqual(fences, 5, "Sprint Plan has 2 charts, Dashboard has 3")
    }

    /// Data integrity vs. the source workbook: 67 backlog items
    /// (CM 35 · SM 25 · V 7) and the dashboard totals that roll up from them.
    func testBacklogMatchesWorkbookTotals() throws {
        let backlog = BootcampSeed.documents[1].body
        func rows(_ prefix: String) -> Int {
            backlog.components(separatedBy: "\n| \(prefix)").count - 1
        }
        XCTAssertEqual(rows("CM-"), 35)
        XCTAssertEqual(rows("SM-"), 25)
        XCTAssertEqual(rows("V-0"), 7)

        let dashboard = BootcampSeed.documents[3].body
        XCTAssertTrue(dashboard.contains("| TOTAL | 67 | 169 |"))
    }
}
