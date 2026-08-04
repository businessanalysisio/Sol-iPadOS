import XCTest
@testable import SolBlockModel

/// The M2 gate backstop: full reparse of a 10k-word document must sit far
/// inside the 50ms keystroke budget (APP-NFR-01). BlockDocument's whole
/// design rests on this staying true — if this test starts failing, the
/// escalation path is true incremental splicing (see BlockDocument docs).
final class PerformanceTests: XCTestCase {

    /// ~10k words across paragraphs, headings, lists, tables and a fence —
    /// the APP-FR-06 tier-1 document size.
    private static let bigDoc: String = {
        var lines: [String] = []
        for section in 0..<50 {
            lines.append("## Mục \(section) · Đặc tả quy trình báo giá ưu đãi")
            for _ in 0..<8 {
                lines.append("Đây là một đoạn văn **quan trọng** với *nhấn mạnh* và `mã` " +
                             String(repeating: "từ ngữ tiếng Việt đặc tả ", count: 8))
            }
            lines.append("- Tiêu chí nghiệm thu số một của mục \(section)")
            lines.append("- Tiêu chí nghiệm thu số hai của mục \(section)")
            lines.append("| ID | Tiêu chí | Ưu tiên |")
            lines.append("|----|----------|---------|")
            lines.append("| AC\(section) | Kế thừa giá theo hợp đồng | Must |")
            lines.append("")
        }
        lines.append("```sol-data type=bar")
        lines.append("week,count"); lines.append("W1,120"); lines.append("W2,180")
        lines.append("```")
        return lines.joined(separator: "\n")
    }()

    func testDocIsActuallyTenThousandWords() {
        let words = Self.bigDoc.split(whereSeparator: \.isWhitespace).count
        XCTAssertGreaterThan(words, 10_000, "perf fixture shrank — the gate below would be meaningless")
    }

    func testFullReparseOfTenThousandWordsStaysInsideKeystrokeBudget() {
        let doc = BlockDocument(text: Self.bigDoc)
        var worst: TimeInterval = 0
        for i in 0..<20 { // 20 simulated keystrokes, keep the WORST case
            let t0 = Date()
            doc.replaceAll(with: Self.bigDoc + "\nkeystroke \(i)")
            worst = max(worst, Date().timeIntervalSince(t0))
        }
        // REGRESSION TRIPWIRE, not the AC measurement: CI runs Debug (-Onone),
        // which is 10–20× slower than the Release build the APP-NFR-01 budget
        // is defined against (25ms parser share of 50ms, measured on the
        // reference device in the M6 perf suite). 100ms Debug ≈ well inside
        // that Release budget; if this trips, implement true incremental
        // splicing (BlockDocument docs) — never just raise the number here.
        XCTAssertLessThan(worst, 0.100,
            "Debug-build reparse tripwire exceeded — time to implement true incremental splicing (BlockDocument docs)")
    }

    func testMeasuredBaseline() {
        measure {
            _ = BlockParser.parse(Self.bigDoc)
        }
    }
}
