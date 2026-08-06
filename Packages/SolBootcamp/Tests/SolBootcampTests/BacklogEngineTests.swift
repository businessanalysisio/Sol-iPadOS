import XCTest
import SolBlockModel
import SolDataBlocks
@testable import SolBootcamp

/// Engine thuần: parse Backlog từ .md, mutation phẫu thuật, dashboard roll-up.
final class BacklogEngineTests: XCTestCase {
    // MARK: - Parse

    func testParseSeedBacklogMatchesWorkbook() {
        let items = BacklogDocument.parse(BootcampSeed.backlog)
        XCTAssertEqual(items.count, 67)
        XCTAssertEqual(items.reduce(0) { $0 + $1.effortDays }, 169)

        func track(_ name: String) -> [BacklogItem] { items.filter { $0.track == name } }
        XCTAssertEqual(track("Course Materials").count, 35)
        XCTAssertEqual(track("Course Materials").reduce(0) { $0 + $1.effortDays }, 89)
        XCTAssertEqual(track("Sales & Marketing").count, 25)
        XCTAssertEqual(track("Sales & Marketing").reduce(0) { $0 + $1.effortDays }, 50)
        XCTAssertEqual(track("Validation & Launch").count, 7)
        XCTAssertEqual(track("Validation & Launch").reduce(0) { $0 + $1.effortDays }, 30)

        // Kiểm tra chéo 1 dòng đầy đủ (V-02 — dòng nhiều phụ thuộc nhất).
        let v02 = items.first { $0.id == "V-02" }!
        XCTAssertEqual(v02.epic, "Beta Cohort & Iteration")
        XCTAssertEqual(v02.title, "Deliver beta cohort (live, JIT)")
        XCTAssertEqual(v02.owner, "Course Lead")
        XCTAssertEqual(v02.priority, "Must")
        XCTAssertEqual(v02.effortDays, 15)
        XCTAssertEqual(v02.dependencies, "CM-31, CM-32, CM-33, V-01")
        XCTAssertEqual(v02.sprint, "Beta Cohort")
        XCTAssertEqual(v02.status, .notStarted)

        // Mọi item seed đều Not started — trạng thái xuất phát của workbook.
        XCTAssertTrue(items.allSatisfy { $0.status == .notStarted })
    }

    // MARK: - Mutation

    func testSettingStatusTouchesExactlyOneLine() {
        let original = BootcampSeed.backlog
        let updated = BacklogDocument.settingStatus(in: original, id: "CM-01", to: .done)

        let before = original.components(separatedBy: "\n")
        let after = updated.components(separatedBy: "\n")
        XCTAssertEqual(before.count, after.count)
        let changed = zip(before, after).filter { $0 != $1 }
        XCTAssertEqual(changed.count, 1, "mutation phải là phẫu thuật — đúng 1 dòng")
        XCTAssertTrue(changed[0].1.hasPrefix("| CM-01 |"))

        // Round-trip: chỉ CM-01 đổi status, 66 item còn lại y nguyên.
        let items = BacklogDocument.parse(updated)
        XCTAssertEqual(items.first { $0.id == "CM-01" }?.status, .done)
        XCTAssertEqual(items.filter { $0.status == .notStarted }.count, 66)
    }

    func testSettingStatusUnknownIDReturnsTextUnchanged() {
        let text = BootcampSeed.backlog
        XCTAssertEqual(BacklogDocument.settingStatus(in: text, id: "CM-99", to: .done), text)
    }

    // MARK: - Dashboard

    func testDashboardRollupsFromStatuses() {
        var text = BootcampSeed.backlog
        text = BacklogDocument.settingStatus(in: text, id: "CM-01", to: .done)   // 2d, Course Materials
        text = BacklogDocument.settingStatus(in: text, id: "SM-01", to: .done)   // 2d, Sales & Marketing
        text = BacklogDocument.settingStatus(in: text, id: "V-02", to: .inProgress)
        let items = BacklogDocument.parse(text)
        let dashboard = DashboardRenderer.render(items: items)

        XCTAssertTrue(dashboard.hasPrefix(DashboardRenderer.marker),
                      "H1 phải khớp marker để lần cập nhật sau tìm đúng file")
        // Tổng thể: 2/67 items · 4/169 ngày · 3% (2·100/67 = 2.99 → 3%).
        XCTAssertTrue(dashboard.contains("**2/67 items · 4/169 person-days · 3%**"))
        // By status.
        XCTAssertTrue(dashboard.contains("| Not started | 64 |"))
        XCTAssertTrue(dashboard.contains("| In progress | 1 | 15 |"))
        XCTAssertTrue(dashboard.contains("| Done | 2 | 4 |"))
        // By track: Course Materials 1/35 done, effort done 2 → 3%.
        XCTAssertTrue(dashboard.contains("| Course Materials | 35 | 1 | 89 | 2 | 3% |"))
        XCTAssertTrue(dashboard.contains("| TOTAL | 67 | 2 | 169 | 4 | 3% |"))
        // By sprint giữ thứ tự lịch: S0 trước, S4 sau Beta Cohort.
        let s0 = dashboard.range(of: "| S0 · Foundations |")!
        let beta = dashboard.range(of: "| Beta Cohort |")!
        let s4 = dashboard.range(of: "| S4 · Iterate & Launch |")!
        XCTAssertTrue(s0.lowerBound < beta.lowerBound && beta.lowerBound < s4.lowerBound)
    }

    /// Dashboard sinh ra phải render sạch qua pipeline thật: mọi sol-data
    /// fence parse thành spec, không rơi vào banner lỗi CSV.
    func testRenderedDashboardParsesThroughRealPipeline() {
        let items = BacklogDocument.parse(
            BacklogDocument.settingStatus(in: BootcampSeed.backlog, id: "CM-01", to: .done))
        let dashboard = DashboardRenderer.render(items: items)

        var fences = 0
        for case let .fence(info, body) in BlockParser.parse(dashboard).blocks
        where DataBlockParser.isSolData(info: info) {
            fences += 1
            switch DataBlockParser.parse(info: info, body: body) {
            case .success(let spec):
                XCTAssertFalse(spec.points.isEmpty)
            case .failure(let error):
                XCTFail("fence “\(info)” — \(error.message)")
            }
        }
        XCTAssertEqual(fences, 3, "pie trạng thái + bar track + line sprint")
    }
}
