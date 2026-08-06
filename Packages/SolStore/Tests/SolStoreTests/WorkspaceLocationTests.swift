import XCTest
@testable import SolStore

/// APP-AC-09 — all four iCloud states have specified behavior, and local→iCloud
/// migration never loses a file (including into a non-empty container).
final class WorkspaceLocationTests: XCTestCase {
    private var tmp: URL!

    override func setUpWithError() throws {
        tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-loc-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    private struct StubUbiquity: UbiquityProviding {
        let result: ICloudStatus
        func status() -> ICloudStatus { result }
    }

    private var localRoot: URL { tmp.appendingPathComponent("local", isDirectory: true) }
    private var container: URL { tmp.appendingPathComponent("icloud", isDirectory: true) }

    // MARK: 4 trạng thái iCloud (APP-AC-09)

    func testAvailableUsesContainer() throws {
        let loc = try WorkspaceLocation.resolve(
            ubiquity: StubUbiquity(result: .available(containerURL: container)), localRoot: localRoot)
        XCTAssertEqual(loc.root, container)
        XCTAssertEqual(loc.backing, .iCloud)
    }

    func testNoAccountFallsBackToFullyFunctionalLocal() throws {
        let loc = try WorkspaceLocation.resolve(
            ubiquity: StubUbiquity(result: .noAccount), localRoot: localRoot)
        XCTAssertEqual(loc.backing, .localFallback(reason: .noAccount))
        // APP-NFR-04: the local workspace is a real workspace, not a stub.
        let store = try DocumentStore(root: loc.root, index: SearchIndex())
        _ = try store.createDocument(named: "Offline vẫn dùng được")
        XCTAssertEqual(try store.listDocuments().count, 1)
    }

    func testDisabledFallsBackToLocal() throws {
        let loc = try WorkspaceLocation.resolve(
            ubiquity: StubUbiquity(result: .disabled), localRoot: localRoot)
        XCTAssertEqual(loc.backing, .localFallback(reason: .disabled))
    }

    func testQuotaFullFallsBackToLocal() throws {
        let loc = try WorkspaceLocation.resolve(
            ubiquity: StubUbiquity(result: .quotaFull), localRoot: localRoot)
        XCTAssertEqual(loc.backing, .localFallback(reason: .quotaFull))
    }

    // MARK: Di trú local → iCloud (APP-FR-15 / EMMA-R-03)

    func testMigrationMovesEveryFile() throws {
        try FileManager.default.createDirectory(at: localRoot, withIntermediateDirectories: true)
        try "a".write(to: localRoot.appendingPathComponent("Một.md"), atomically: true, encoding: .utf8)
        try "b".write(to: localRoot.appendingPathComponent("Hai.md"), atomically: true, encoding: .utf8)

        let moves = try WorkspaceLocation.migrate(localRoot: localRoot, into: container)

        XCTAssertEqual(moves.count, 2)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(at: localRoot, includingPropertiesForKeys: nil), [])
        let migrated = try FileManager.default.contentsOfDirectory(at: container, includingPropertiesForKeys: nil)
            .map(\.lastPathComponent).sorted()
        XCTAssertEqual(migrated, ["Hai.md", "Một.md"])
    }

    func testMigrationIntoNonEmptyContainerSuffixesInsteadOfOverwriting() throws {
        try FileManager.default.createDirectory(at: localRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        try "bản iCloud".write(to: container.appendingPathComponent("FRS.md"), atomically: true, encoding: .utf8)
        try "bản local".write(to: localRoot.appendingPathComponent("FRS.md"), atomically: true, encoding: .utf8)

        _ = try WorkspaceLocation.migrate(localRoot: localRoot, into: container)

        // Both versions survive — the collision took the APP-FR-03 suffix.
        XCTAssertEqual(
            try String(contentsOf: container.appendingPathComponent("FRS.md"), encoding: .utf8), "bản iCloud")
        XCTAssertEqual(
            try String(contentsOf: container.appendingPathComponent("FRS 2.md"), encoding: .utf8), "bản local")
    }

    // MARK: Di trú tự động ở bootstrap (O13 — nối migrate vào đường mở app)

    func testMigrateIfNeededMovesWorkspaceAndRemovesEmptyLocalRoot() throws {
        try FileManager.default.createDirectory(at: localRoot, withIntermediateDirectories: true)
        try "nội dung".write(to: localRoot.appendingPathComponent("Ghi chú.md"),
                             atomically: true, encoding: .utf8)

        XCTAssertEqual(WorkspaceLocation.migrateIfNeeded(localRoot: localRoot, into: container), 1)

        XCTAssertEqual(
            try String(contentsOf: container.appendingPathComponent("Ghi chú.md"), encoding: .utf8),
            "nội dung")
        // Thư mục local đã rỗng thì bị gỡ — lần mở sau không di trú lại.
        XCTAssertFalse(FileManager.default.fileExists(atPath: localRoot.path))
        XCTAssertEqual(WorkspaceLocation.migrateIfNeeded(localRoot: localRoot, into: container), 0)
    }

    func testMigrateIfNeededIsNoopWhenLocalRootMissingOrEmpty() throws {
        // Chưa từng có workspace cục bộ (cài mới khi iCloud sẵn sàng).
        XCTAssertEqual(WorkspaceLocation.migrateIfNeeded(localRoot: localRoot, into: container), 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: container.path),
                       "no-op thì không được tạo gì trong container")

        // Thư mục cục bộ rỗng cũng là no-op (không có gì để mất).
        try FileManager.default.createDirectory(at: localRoot, withIntermediateDirectories: true)
        XCTAssertEqual(WorkspaceLocation.migrateIfNeeded(localRoot: localRoot, into: container), 0)
    }
}
