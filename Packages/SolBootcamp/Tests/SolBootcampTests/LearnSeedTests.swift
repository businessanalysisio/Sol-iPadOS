import XCTest
import SolStore
import SolBlockModel
import SolDataBlocks
@testable import SolBootcamp

/// Seed "Bootcamp Learn" — install-once semantics + bộ giáo trình phải sống
/// sót qua pipeline parse thật, không chỉ nhìn có vẻ đúng.
final class LearnSeedTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-learn-seed-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeStore() throws -> DocumentStore {
        try DocumentStore(root: root, index: SearchIndex())
    }

    func testInstallsOnceOnFreshWorkspace() throws {
        let store = try makeStore()
        XCTAssertTrue(try LearnSeed.installIfNeeded(into: store))

        let titles = try store.listDocuments().map(\.title).sorted()
        XCTAssertEqual(titles, [
            "BA Bootcamp — 10 · Curriculum",
            "BA Bootcamp — 11 · Module 1",
            "BA Bootcamp — 12 · Module 2",
            "BA Bootcamp — 13 · Module 3",
            "BA Bootcamp — 14 · Module 4",
            "BA Bootcamp — 15 · Module 5",
        ])

        // Second call is a no-op — no duplicates.
        XCTAssertFalse(try LearnSeed.installIfNeeded(into: store))
        XCTAssertEqual(try store.listDocuments().count, 6)
    }

    /// Hai bộ seed có marker riêng — workspace đã có Bootcamp OS (seed trước
    /// khi Learn ra đời) vẫn nhận được giáo trình, và ngược lại.
    func testCoexistsWithBootcampSeed() throws {
        let store = try makeStore()
        XCTAssertTrue(try BootcampSeed.installIfNeeded(into: store))
        XCTAssertTrue(try LearnSeed.installIfNeeded(into: store))
        XCTAssertEqual(try store.listDocuments().count, 10)
    }

    /// User intent wins: xóa tài liệu giáo trình thì lần mở sau không được
    /// hồi sinh (marker sống lâu hơn tài liệu).
    func testDeletedSeedStaysDeletedAcrossRelaunch() throws {
        let store = try makeStore()
        _ = try LearnSeed.installIfNeeded(into: store)
        let curriculum = try XCTUnwrap(try store.listDocuments()
            .first { $0.title.contains("Curriculum") })
        try store.softDelete(curriculum)

        let reopened = try makeStore()
        XCTAssertFalse(try LearnSeed.installIfNeeded(into: reopened))
        XCTAssertEqual(try reopened.listDocuments().count, 5)
    }

    /// Seeded docs go through createDocument → searchable via FTS (APP-FR-04).
    func testSeedContentIsIndexedForSearch() throws {
        let store = try makeStore()
        _ = try LearnSeed.installIfNeeded(into: store)
        XCTAssertFalse(try store.search("BPMN").isEmpty)
        XCTAssertFalse(try store.search("Gherkin").isEmpty)
        XCTAssertFalse(try store.search("elicitation").isEmpty)
    }

    /// Mọi sol-data fence trong bộ seed phải parse thành spec render được —
    /// tài liệu seed hiện banner lỗi CSV là shipping bug.
    func testAllSeedDataBlocksParse() throws {
        var fences = 0
        for doc in LearnSeed.documents {
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
        XCTAssertEqual(fences, 1, "Curriculum có 1 bar chart thời lượng theo module")
    }

    /// Data integrity vs. syllabus: tổng phút trong chart khớp tổng phút
    /// của bảng Curriculum (chart là dữ liệu tĩnh, phải khớp nguồn).
    func testCurriculumChartMatchesTableTotals() {
        let lessons = CurriculumDocument.parse(LearnSeed.curriculum)
        for n in 1...5 {
            let minutes = lessons
                .filter { $0.moduleNumber == n }
                .reduce(0) { $0 + $1.durationMinutes }
            XCTAssertTrue(LearnSeed.curriculum.contains("Module \(n),\(minutes)"),
                          "chart phải khớp bảng cho Module \(n) (\(minutes) phút)")
        }
        XCTAssertEqual(lessons.reduce(0) { $0 + $1.durationMinutes }, 970)
    }
}
