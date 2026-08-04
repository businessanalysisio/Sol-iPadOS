import XCTest
@testable import SolDataBlocks

final class DataBlockTests: XCTestCase {

    // MARK: Info-string attributes

    func testInfoStringParsing() {
        let attrs = DataBlockParser.attributes(of: #"sol-data type=bar title="Yêu cầu báo giá/tuần" src=data/p.csv"#)
        XCTAssertEqual(attrs["type"], "bar")
        XCTAssertEqual(attrs["title"], "Yêu cầu báo giá/tuần") // quoted, keeps spaces
        XCTAssertEqual(attrs["src"], "data/p.csv")
    }

    func testIsSolDataDetection() {
        XCTAssertTrue(DataBlockParser.isSolData(info: "sol-data"))
        XCTAssertTrue(DataBlockParser.isSolData(info: "sol-data type=pie"))
        XCTAssertFalse(DataBlockParser.isSolData(info: "sol-database")) // no prefix false-positive
        XCTAssertFalse(DataBlockParser.isSolData(info: "swift"))
    }

    func testUnknownTypeIsAClearError() {
        let r = DataBlockParser.parse(info: "sol-data type=radar", body: ["a,1"])
        XCTAssertEqual(r, .failure(.unknownType("radar")))
    }

    func testTypeDefaultsToBar() throws {
        let spec = try DataBlockParser.parse(info: "sol-data", body: ["W1,120"]).get()
        XCTAssertEqual(spec.type, .bar)
    }

    // MARK: CSV — mockup behavior + deterministic errors (APP-FR-09 AC)

    func testMockupCSVWithHeaderRow() throws {
        let points = try DataBlockParser.parseCSV(["week,count", "W1,120", "W2,180", "W3,146", "W4,215"]).get()
        XCTAssertEqual(points.map(\.label), ["W1", "W2", "W3", "W4"])
        XCTAssertEqual(points.map(\.value), [120, 180, 146, 215])
    }

    func testBadRowReportsFirstErrorLineVerbatim() {
        let r = DataBlockParser.parseCSV(["week,count", "W1,120", "W2;180"])
        XCTAssertEqual(r, .failure(.invalidRow(line: 3, content: "W2;180")))
        if case .failure(let e) = r {
            XCTAssertEqual(e.message,
                "Không đọc được CSV — cần dạng `W1,120` (dòng lỗi đầu tiên: 3: “W2;180”)")
        }
    }

    func testEmptyBodyIsEmptyDataError() {
        XCTAssertEqual(DataBlockParser.parseCSV(["", "  "]), .failure(.emptyData))
    }

    func testRowLimitEnforced() {
        var rows = (1...DataBlockParser.maxRows + 1).map { "R\($0),\($0)" }
        rows.insert("label,value", at: 0)
        XCTAssertEqual(DataBlockParser.parseCSV(rows),
                       .failure(.tooManyRows(limit: DataBlockParser.maxRows)))
    }

    func testVietnameseLabelsAndDecimalValues() throws {
        let points = try DataBlockParser.parseCSV(["Quý một,12.5", "Quý hai,17.25"]).get()
        XCTAssertEqual(points[0], DataPoint(label: "Quý một", value: 12.5))
    }

    func testSrcBlockWithEmptyBodyIsValid() throws {
        let spec = try DataBlockParser.parse(info: "sol-data type=line src=data/p.csv", body: []).get()
        XCTAssertEqual(spec.sourcePath, "data/p.csv")
        XCTAssertTrue(spec.points.isEmpty)
    }

    // MARK: Downsampling (M-04: ≤200 điểm, giữ điểm đầu/cuối, ghi chú N/M)

    func testNoDownsampleAtOrBelowLimit() {
        let pts = (1...200).map { DataPoint(label: "P\($0)", value: Double($0)) }
        let s = Downsampler.downsample(pts)
        XCTAssertEqual(s.points.count, 200)
        XCTAssertFalse(s.isDownsampled)
        XCTAssertNil(s.note)
    }

    func testDownsampleKeepsEndpointsAndNotes() {
        let pts = (1...1000).map { DataPoint(label: "P\($0)", value: Double($0)) }
        let s = Downsampler.downsample(pts)
        XCTAssertLessThanOrEqual(s.points.count, 200)
        XCTAssertEqual(s.points.first, pts.first) // exact endpoints survive
        XCTAssertEqual(s.points.last, pts.last)
        XCTAssertEqual(s.note, "hiển thị \(s.points.count)/1000 điểm")
        // Bucket means preserve monotone trend on monotone input.
        XCTAssertTrue(zip(s.points, s.points.dropFirst()).allSatisfy { $0.value <= $1.value })
    }

    // MARK: Insight per-type (EMMA-06 resolution)

    func testBarLineInsightIsLastPeriodChange() {
        let pts = [DataPoint(label: "W3", value: 146), DataPoint(label: "W4", value: 215)]
        XCTAssertEqual(InsightGenerator.insight(for: .bar, points: pts),
                       "W4 tăng 47% so với W3.")
        let down = [DataPoint(label: "W3", value: 200), DataPoint(label: "W4", value: 150)]
        XCTAssertEqual(InsightGenerator.insight(for: .line, points: down),
                       "W4 giảm 25% so với W3.")
    }

    func testPieInsightIsLargestShare() {
        let pts = [DataPoint(label: "Logistics", value: 45),
                   DataPoint(label: "Bán lẻ", value: 30),
                   DataPoint(label: "Khác", value: 25)]
        XCTAssertEqual(InsightGenerator.insight(for: .pie, points: pts),
                       "Logistics chiếm tỷ trọng lớn nhất — 45%.")
    }

    func testInsightHiddenWhenInsufficientOrUndefined() {
        XCTAssertNil(InsightGenerator.insight(for: .bar, points: [DataPoint(label: "W1", value: 1)]))
        XCTAssertNil(InsightGenerator.insight(for: .pie, points: [DataPoint(label: "A", value: 5)]))
        // % change from a zero base is undefined — no insight, no crash.
        XCTAssertNil(InsightGenerator.insight(for: .bar, points: [
            DataPoint(label: "W1", value: 0), DataPoint(label: "W2", value: 10)]))
    }

    // MARK: VoiceOver summary (APP-FR-09 AC: > 25 điểm đọc summary)

    func testAccessibilitySummaryNamesExtremesAndLast() {
        let pts = (1...100).map { DataPoint(label: "P\($0)", value: Double($0 == 50 ? 999 : $0)) }
        let s = InsightGenerator.accessibilitySummary(points: pts)
        XCTAssertTrue(s.contains("100 điểm"))
        XCTAssertTrue(s.contains("Cao nhất P50: 999"))
        XCTAssertTrue(s.contains("Điểm cuối P100: 100"))
    }
}
