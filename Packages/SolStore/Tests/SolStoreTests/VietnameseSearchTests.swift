import XCTest
@testable import SolStore

/// PRD v1.2 Phụ lục C — the M1 gate test set for Vietnamese search.
final class VietnameseSearchTests: XCTestCase {

    // MARK: Normalizer

    func testFoldStripsToneMarksAndHats() {
        XCTAssertEqual(VietnameseNormalizer.fold("đặc tả"), "dac ta")
        XCTAssertEqual(VietnameseNormalizer.fold("đường"), "duong")
        XCTAssertEqual(VietnameseNormalizer.fold("báo giá ưu đãi"), "bao gia uu dai")
        XCTAssertEqual(VietnameseNormalizer.fold("ĐẶC TẢ — Quy trình"), "dac ta — quy trinh")
    }

    func testNFCandNFDFoldIdentically() {
        let nfc = "đặc tả ế ộ ờ ưu"
        let nfd = nfc.decomposedStringWithCanonicalMapping
        XCTAssertNotEqual(Array(nfc.utf16), Array(nfd.utf16))
        XCTAssertEqual(VietnameseNormalizer.fold(nfc), VietnameseNormalizer.fold(nfd))
    }

    // MARK: Index round-trips (Phụ lục C cases 1–4)

    func testDiacriticFreeQueryFindsVietnameseContent() throws {
        let index = try SearchIndex()
        try index.index(docID: "d1", title: "Quy trình Báo giá — Đặc tả chức năng", body: "SLA phản hồi 4 giờ")
        try index.index(docID: "d2", title: "Biên bản workshop", body: "Quyết định về đường vận chuyển ký gửi")

        XCTAssertEqual(try index.search("dac ta"), ["d1"])   // đ + tone folded
        XCTAssertEqual(try index.search("duong"), ["d2"])    // đ→d fold (the PAUL-02 case)
        XCTAssertEqual(try index.search("bao gia"), ["d1"])
        XCTAssertEqual(try index.search("Đặc Tả"), ["d1"])   // accented query also works
    }

    func testCombiningFormContentIsFoundByPrecomposedQuery() throws {
        let index = try SearchIndex()
        let nfdBody = "đặc tả ưu đãi".decomposedStringWithCanonicalMapping
        try index.index(docID: "d3", title: "NFD", body: nfdBody)
        XCTAssertEqual(try index.search("đặc tả"), ["d3"])
        XCTAssertEqual(try index.search("uu dai"), ["d3"])
    }

    func testPrefixMatching() throws {
        let index = try SearchIndex()
        try index.index(docID: "d4", title: "Pipeline theo tuần", body: "")
        XCTAssertEqual(try index.search("pipe"), ["d4"])
    }

    func testEmptyQueryReturnsNothing() throws {
        let index = try SearchIndex()
        try index.index(docID: "d5", title: "Bất kỳ", body: "")
        XCTAssertEqual(try index.search("   "), [])
    }
}
