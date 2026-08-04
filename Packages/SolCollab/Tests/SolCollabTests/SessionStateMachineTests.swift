import XCTest
@testable import SolCollab

/// APP-FR-13/14 Layer-1 gates: every row of the PRD state-machine table has a
/// test; role enforcement verified AT THE RELAY (APP-AC-06); G2 snapshot
/// semantics on every end path. Clock is injectable — the 15-minute timeout
/// is deterministic.
final class SessionStateMachineTests: XCTestCase {
    private var clock: Date!
    private var hub: MockRelayHub!

    override func setUp() {
        super.setUp()
        clock = Date(timeIntervalSince1970: 1_754_300_000)
        hub = MockRelayHub(ownerName: "Sol", now: { self.clock })
    }

    private func makeOwnerSession() -> CollabSession {
        CollabSession(memberID: "m0", displayName: "Sol", role: .owner,
                      transport: hub.ownerTransport())
    }

    private func joinGuest(_ name: String) -> CollabSession {
        guard case .success(let transport) = hub.join(displayName: name) else {
            fatalError("join failed")
        }
        return CollabSession(memberID: transport.memberID, displayName: name,
                             role: .viewer, transport: transport)
    }

    // MARK: 3 người gõ đồng thời hội tụ (qua relay, không chỉ CRDT thuần)

    func testThreeMembersConvergeThroughRelay() {
        let owner = makeOwnerSession()
        let hao = joinGuest("Hảo")
        let phu = joinGuest("Phú")
        hub.setRole("m1", to: .editor)
        hub.setRole("m2", to: .editor)

        _ = owner.insert("a", at: 0)
        _ = hao.insert("b", at: 0)
        _ = phu.insert("c", at: 0)
        _ = owner.insert("!", at: owner.text.count)

        XCTAssertEqual(owner.text, hao.text)
        XCTAssertEqual(hao.text, phu.text)
        XCTAssertEqual(owner.text.count, 4)
    }

    // MARK: Guest join mặc định Viewer + chặn ghi Ở RELAY (APP-AC-06)

    func testJoinDefaultsToViewerAndRelayRejectsViewerUpdate() {
        let owner = makeOwnerSession()
        _ = owner.insert("x", at: 0)

        guard case .success(let rawTransport) = hub.join(displayName: "Khách") else {
            return XCTFail("join failed")
        }
        // Bypass mọi guard client-side: bắn thẳng frame update vào relay.
        var rejected = false
        rawTransport.onEnvelope = { env in
            if case .err(let code) = env.frame, code == RelayErrorCode.forbiddenRole { rejected = true }
        }
        rawTransport.send(.update(bytes: CRDTCoding.encode([])))
        XCTAssertTrue(rejected, "relay phải từ chối update từ Viewer, không phụ thuộc UI")
    }

    func testRoleChangeEffectiveImmediately() {
        _ = makeOwnerSession()
        let guest = joinGuest("Hảo")
        XCTAssertEqual(guest.insert("k", at: 0), .failure(.viewerCannotEdit))

        hub.setRole("m1", to: .editor)
        XCTAssertEqual(guest.role, .editor) // role_changed frame landed
        XCTAssertEqual(guest.insert("k", at: 0), .success(()))
    }

    // MARK: Owner mất mạng → SUSPENDED; quay lại ≤15' → resume + replay held ops

    func testSuspendResumeReplaysHeldGuestOps() {
        let owner = makeOwnerSession()
        let hao = joinGuest("Hảo")
        hub.setRole("m1", to: .editor)
        _ = owner.insert("a", at: 0)

        hub.ownerDisconnected()
        XCTAssertEqual(hao.state, .suspended)

        // Guest-editor keeps typing while suspended — buffered locally.
        _ = hao.insert("b", at: 1)
        _ = hao.insert("c", at: 2)
        XCTAssertEqual(hao.heldOps.count, 2)
        XCTAssertEqual(hao.text, "abc") // local replica has them (G2)

        // Owner returns within 15 minutes.
        clock = clock.addingTimeInterval(10 * 60)
        let ownerTransport = hub.ownerReconnected()
        XCTAssertNotNil(ownerTransport)
        let ownerBack = CollabSession(memberID: "m0", displayName: "Sol", role: .owner,
                                      transport: ownerTransport!)
        ownerBack.sendPresence(anchor: 0, length: 0) // triggers nothing; session resumes via frames

        XCTAssertEqual(hao.state, .active)
        XCTAssertTrue(hao.heldOps.isEmpty, "held ops phải được replay khi resume")
    }

    // MARK: Timeout >15' → END với quy tắc snapshot (held ops không mất — G2)

    func testTimeoutEndsSessionAndSnapshotKeepsHeldOps() {
        let owner = makeOwnerSession()
        let hao = joinGuest("Hảo")
        hub.setRole("m1", to: .editor)
        _ = owner.insert("a", at: 0)

        hub.ownerDisconnected()
        _ = hao.insert("b", at: 1) // held while suspended

        clock = clock.addingTimeInterval(16 * 60)
        hub.checkTimeout() // the DO alarm firing

        XCTAssertEqual(hao.state, .ended)
        XCTAssertEqual(hao.endReason, .timeout)
        XCTAssertEqual(hao.endSnapshot, "ab", "snapshot phải chứa cả thao tác tạm giữ (G2)")
        XCTAssertEqual(hao.insert("x", at: 0), .failure(.sessionEnded)) // read-only sau END
    }

    // MARK: Revoke link ≠ end session (APP-FR-14 / PAUL-09)

    func testRevokeBlocksNewJoinsOnlyExistingMembersContinue() {
        let owner = makeOwnerSession()
        let hao = joinGuest("Hảo")
        hub.setRole("m1", to: .editor)

        hub.revokeLink()
        if case .success = hub.join(displayName: "Người mới") {
            XCTFail("join sau revoke phải bị chặn")
        }
        // Người trong phiên vẫn làm việc bình thường.
        _ = hao.insert("z", at: 0)
        XCTAssertEqual(owner.text, "z")
    }

    // MARK: End session — mọi guest giữ snapshot local read-only

    func testOwnerEndGivesEveryGuestASnapshot() {
        let owner = makeOwnerSession()
        let hao = joinGuest("Hảo")
        let phu = joinGuest("Phú")
        hub.setRole("m1", to: .editor)
        _ = owner.insert("n", at: 0)
        _ = hao.insert("m", at: 1)

        hub.endSession()

        for (session, name) in [(hao, "Hảo"), (phu, "Phú"), (owner, "owner")] {
            XCTAssertEqual(session.state, .ended, name)
            XCTAssertEqual(session.endReason, .ownerEnd, name)
            XCTAssertEqual(session.endSnapshot, "nm", name)
        }
    }

    // MARK: Mở link sau END → GONE ("Phiên đã kết thúc")

    func testJoinAfterEndReturnsGone() {
        _ = makeOwnerSession()
        hub.endSession()
        guard case .failure(let error) = hub.join(displayName: "Trễ") else {
            return XCTFail("join sau END phải fail")
        }
        XCTAssertEqual(error, .gone)
    }

    // MARK: Guest mới nhận snapshot qua relay (snapshot_req flow)

    func testLateJoinerReceivesDocumentSnapshot() {
        let owner = makeOwnerSession()
        for (i, ch) in "đề án".map(String.init).enumerated() {
            _ = owner.insert(ch, at: i)
        }
        let late = joinGuest("Muộn")
        XCTAssertEqual(late.text, "đề án")
    }
}
