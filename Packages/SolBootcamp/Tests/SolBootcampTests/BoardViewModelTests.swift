import XCTest
import SolStore
@testable import SolBootcamp

/// Board ↔ DocumentStore: discovery, ghi đúng bất biến journal-before-write,
/// Dashboard tái sinh (kể cả khi người dùng đã xóa nó).
final class BoardViewModelTests: XCTestCase {
    private var root: URL!
    private var store: DocumentStore!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-board-\(UUID().uuidString)", isDirectory: true)
        store = try DocumentStore(root: root, index: SearchIndex())
        _ = try BootcampSeed.installIfNeeded(into: store)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testDiscoversBacklogAndComputesTotals() {
        let model = BootcampBoardViewModel(store: store)
        XCTAssertEqual(model.totalItems, 67)
        XCTAssertEqual(model.totalEffort, 169)
        XCTAssertEqual(model.doneItems, 0)
        XCTAssertEqual(model.sections.map(\.name),
                       ["Course Materials", "Sales & Marketing", "Validation & Launch"])
        XCTAssertEqual(model.progress, 0)
    }

    func testSetStatusWritesBacklogAndRegeneratesDashboard() throws {
        let model = BootcampBoardViewModel(store: store, actor: "iPad-Test")
        model.setStatus(.done, for: "CM-01")

        // Backlog trên đĩa đã đổi đúng dòng; model phản ánh ngay.
        let backlog = try XCTUnwrap(BootcampBoardViewModel.backlogDocument(in: store))
        XCTAssertTrue(try store.contents(of: backlog).contains("\n| CM-01 |"))
        XCTAssertEqual(BacklogDocument.parse(try store.contents(of: backlog))
            .first { $0.id == "CM-01" }?.status, .done)
        XCTAssertEqual(model.doneItems, 1)
        XCTAssertEqual(model.doneEffort, 2)

        // Journal-before-write đã hoàn tất chu trình: pending phải sạch.
        XCTAssertNil(store.journal.pending(docID: backlog.id))
        // Version APP-FR-12: có bản ghi actor/operation cho lần đổi status.
        let versions = try store.versions.list(docID: backlog.id) // newest-first
        XCTAssertEqual(versions.first?.actor, "iPad-Test")
        XCTAssertEqual(versions.first?.operation, .edit)

        // Dashboard đã là bản roll-up sinh tự động (thay bản seed tĩnh).
        let dashboard = try XCTUnwrap((try store.listDocuments()).first { doc in
            (try? store.contents(of: doc))?.hasPrefix(DashboardRenderer.marker) == true
        })
        XCTAssertTrue(try store.contents(of: dashboard)
            .contains("**1/67 items · 2/169 person-days · 1%**"))
    }

    func testDashboardRecreatedIfUserDeletedIt() throws {
        // Người dùng xóa Dashboard seed → đổi status vẫn sinh lại bản mới
        // (Dashboard là output dẫn xuất, không phải nội dung gốc).
        let seedDashboard = try XCTUnwrap((try store.listDocuments())
            .first { $0.title.contains("Dashboard") })
        try store.softDelete(seedDashboard)

        let model = BootcampBoardViewModel(store: store)
        model.setStatus(.inProgress, for: "SM-05")

        let regenerated = (try store.listDocuments()).first { doc in
            (try? store.contents(of: doc))?.hasPrefix(DashboardRenderer.marker) == true
        }
        XCTAssertNotNil(regenerated)
        XCTAssertTrue(try store.contents(of: XCTUnwrap(regenerated))
            .contains("| In progress | 1 | 3 |"))
    }

    func testSetStatusOnMissingBacklogIsSafeNoop() throws {
        for doc in try store.listDocuments() { try store.softDelete(doc) }
        let model = BootcampBoardViewModel(store: store)
        XCTAssertEqual(model.totalItems, 0)
        model.setStatus(.done, for: "CM-01") // không crash, không tạo gì
        XCTAssertTrue(try store.listDocuments().isEmpty)
    }
}
