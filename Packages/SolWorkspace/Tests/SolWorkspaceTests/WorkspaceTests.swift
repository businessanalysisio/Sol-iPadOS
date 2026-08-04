import XCTest
import SolStore
@testable import SolWorkspace

final class WorkspaceTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-ws-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeModel(backing: WorkspaceLocation.Backing = .iCloud) throws -> WorkspaceViewModel {
        let store = try DocumentStore(root: root, index: SearchIndex())
        return WorkspaceViewModel(store: store, backing: backing)
    }

    // Phụ lục A is a CLOSED list — this test fails if anyone adds/removes a
    // command without amending the PRD (APP-FR-05 AC).
    func testCommandListMatchesPhuLucA() {
        XCTAssertEqual(
            SolCommandID.allCases.map(\.rawValue),
            ["insertTable", "insertDataBlock", "exportSnapshot", "newDocument",
             "paneMode", "findInDocument", "findInWorkspace", "openTrash"],
            "Danh sách lệnh v1 là danh sách ĐÓNG (PRD v1.2 Phụ lục A) — sửa PRD trước khi sửa enum này."
        )
        // ⌘F must belong to find-in-document, ⌘⇧F to workspace (EMMA-R-02).
        XCTAssertEqual(SolCommandID.findInDocument.shortcutLabel, "⌘F")
        XCTAssertEqual(SolCommandID.findInWorkspace.shortcutLabel, "⌘⇧F")
    }

    func testNewDocumentThenSearchAndDelete() throws {
        let model = try makeModel()
        model.newDocument()
        XCTAssertEqual(model.documents.count, 1)

        model.query = "tai lieu chua dat ten"
        XCTAssertEqual(model.documents.count, 1)

        model.query = "khong ton tai"
        XCTAssertEqual(model.documents.count, 0)

        model.query = ""
        model.softDelete(model.documents[0])
        XCTAssertEqual(model.documents.count, 0)
        XCTAssertEqual(model.trashItems.count, 1)

        model.restore(model.trashItems[0])
        XCTAssertEqual(model.documents.count, 1)
        XCTAssertEqual(model.trashItems.count, 0)
    }

    // Chip theo pha (M-02): M1 chip must never claim iCloud state.
    func testChipOnlyClaimsLocalSaveInM1() throws {
        XCTAssertEqual(try makeModel(backing: .iCloud).chipText, "Đã lưu cục bộ")
        XCTAssertEqual(try makeModel(backing: .localFallback(reason: .noAccount)).chipText, "Đã lưu cục bộ")
    }

    // APP-FR-15: each fallback state has a distinct, truthful notice.
    func testFallbackNotices() throws {
        XCTAssertNil(try makeModel(backing: .iCloud).fallbackNotice)
        XCTAssertTrue(try makeModel(backing: .localFallback(reason: .noAccount))
            .fallbackNotice?.contains("Chưa đăng nhập iCloud") == true)
        XCTAssertTrue(try makeModel(backing: .localFallback(reason: .quotaFull))
            .fallbackNotice?.contains("hết dung lượng") == true)
    }
}
