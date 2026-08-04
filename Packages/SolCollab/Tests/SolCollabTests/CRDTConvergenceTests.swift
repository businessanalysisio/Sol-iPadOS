import XCTest
@testable import SolCollab

/// APP-FR-13 AC #1: "3 người gõ đồng thời hội tụ về cùng nội dung."
/// Deterministic adversarial tests — seeded PRNG, no wall clock.
final class CRDTConvergenceTests: XCTestCase {

    /// Tiny deterministic PRNG (LCG) — reproducible failures.
    private struct LCG {
        var state: UInt64
        mutating func next(_ bound: Int) -> Int {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Int(state >> 33) % max(1, bound)
        }
    }

    func testSequentialTypingRoundTrips() {
        let a = TextCRDT(actor: "A")
        var ops: [CRDTOp] = []
        for (i, ch) in "đặc tả ưu đãi".map(String.init).enumerated() {
            ops.append(a.localInsert(ch, atVisible: i))
        }
        XCTAssertEqual(a.text, "đặc tả ưu đãi")

        let b = TextCRDT(actor: "B")
        ops.forEach(b.apply)
        XCTAssertEqual(b.text, "đặc tả ưu đãi")
    }

    func testConcurrentInsertsAtSamePositionConvergeInAnyOrder() {
        // A and B both type at the head, concurrently, then exchange.
        let a = TextCRDT(actor: "A"), b = TextCRDT(actor: "B")
        let opA = a.localInsert("x", atVisible: 0)
        let opB = b.localInsert("y", atVisible: 0)
        a.apply(opB); b.apply(opA)
        XCTAssertEqual(a.text, b.text)

        // Third replica sees them in the opposite order.
        let c = TextCRDT(actor: "C")
        c.apply(opB); c.apply(opA)
        XCTAssertEqual(c.text, a.text)
    }

    func testDeleteInsertConcurrencyConverges() {
        let a = TextCRDT(actor: "A"), b = TextCRDT(actor: "B")
        var shared: [CRDTOp] = []
        for (i, ch) in "abc".map(String.init).enumerated() {
            shared.append(a.localInsert(ch, atVisible: i))
        }
        shared.forEach(b.apply)

        let del = a.localDelete(atVisible: 1)!      // A deletes "b"
        let ins = b.localInsert("Z", atVisible: 2)  // B inserts after "b" concurrently
        a.apply(ins); b.apply(del)
        XCTAssertEqual(a.text, b.text)
        XCTAssertEqual(a.text, "aZc")
    }

    func testIdempotentReplay() {
        let a = TextCRDT(actor: "A")
        let op = a.localInsert("q", atVisible: 0)
        a.apply(op); a.apply(op) // duplicate delivery (relay replay buffer)
        XCTAssertEqual(a.text, "q")
    }

    func testFuzzThreeActorsConverge() {
        var rng = LCG(state: 20260804)
        for round in 0..<20 {
            let actors = [TextCRDT(actor: "A"), TextCRDT(actor: "B"), TextCRDT(actor: "C")]
            var allOps: [[CRDTOp]] = [[], [], []]
            // Each actor performs 30 random local edits on its own replica.
            for (idx, replica) in actors.enumerated() {
                for _ in 0..<30 {
                    let visible = replica.text.count
                    if visible > 0, rng.next(4) == 0 {
                        if let op = replica.localDelete(atVisible: rng.next(visible)) {
                            allOps[idx].append(op)
                        }
                    } else {
                        let ch = String(UnicodeScalar(UInt8(97 + rng.next(26))))
                        allOps[idx].append(replica.localInsert(ch, atVisible: rng.next(visible + 1)))
                    }
                }
            }
            // Deliver every other actor's ops in per-round shuffled order.
            for (idx, replica) in actors.enumerated() {
                var foreign = allOps.enumerated().filter { $0.offset != idx }.flatMap(\.element)
                // Fisher–Yates with the seeded PRNG.
                for i in stride(from: foreign.count - 1, to: 0, by: -1) {
                    foreign.swapAt(i, rng.next(i + 1))
                }
                foreign.forEach(replica.apply)
            }
            XCTAssertEqual(actors[0].text, actors[1].text, "round \(round) A≠B")
            XCTAssertEqual(actors[1].text, actors[2].text, "round \(round) B≠C")
        }
    }

    func testSnapshotOpsReconstructReplica() {
        let a = TextCRDT(actor: "A")
        for (i, ch) in "báo giá".map(String.init).enumerated() {
            _ = a.localInsert(ch, atVisible: i)
        }
        _ = a.localDelete(atVisible: 0)

        let joiner = TextCRDT(actor: "D")
        a.snapshotOps().forEach(joiner.apply)
        XCTAssertEqual(joiner.text, a.text)
    }
}
