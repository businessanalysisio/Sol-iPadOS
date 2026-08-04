import Foundation

/// In-process stand-in for the Durable Object — implements SPEC-RELAY §4
/// faithfully enough to be the Layer-1 test double AND the executable
/// reference A3 builds against: seq assignment, role enforcement on update
/// (APP-AC-06), the full §4.3 state machine with an injectable clock for the
/// 15-minute SUSPENDED timer, revoke ≠ end, and the 512-frame replay buffer.
public final class MockRelayHub {
    public static let suspendTimeout: TimeInterval = 15 * 60
    public static let bufferSize = 512

    public private(set) var state: SessionState = .active
    public private(set) var members: [MemberID: Member] = [:]
    private var transports: [MemberID: MockRelayTransport] = [:]
    private var seq: UInt64 = 0
    private var buffer: [Envelope] = []
    private var linkRevoked = false
    private var ownerID: MemberID
    private var suspendedAt: Date?
    private let now: () -> Date

    public init(ownerName: String, now: @escaping () -> Date = Date.init) {
        self.now = now
        ownerID = "m0"
        members[ownerID] = Member(id: ownerID, displayName: ownerName, role: .owner)
    }

    // MARK: Lifecycle (SPEC-RELAY §4.1)

    /// Join via share link — default role is ALWAYS viewer (APP-BR-01).
    public func join(displayName: String) -> Result<MockRelayTransport, String> {
        guard state != .ended else { return .failure(RelayErrorCode.gone) }
        guard !linkRevoked else { return .failure(RelayErrorCode.linkRevoked) }
        let id = "m\(members.count)"
        let member = Member(id: id, displayName: displayName, role: .viewer)
        members[id] = member
        let transport = attach(memberID: id)
        broadcast(.memberJoined(member), from: id, excluding: id)
        transport.deliver(Envelope(seq: seq, from: "relay",
                                   frame: .welcome(members: Array(members.values), state: state, sinceSeq: seq)))
        return .success(transport)
    }

    public func ownerTransport() -> MockRelayTransport {
        attach(memberID: ownerID)
    }

    public func setRole(_ member: MemberID, to role: MemberRole) {
        guard members[member] != nil, role != .owner else { return }
        members[member]?.role = role
        broadcast(.roleChanged(member: member, role: role), from: ownerID)
    }

    /// Revoke link — blocks NEW joins only; people in-session are unaffected
    /// (APP-FR-14 / PAUL-09).
    public func revokeLink() {
        linkRevoked = true
    }

    /// End session — everyone disconnected under the snapshot rules.
    public func endSession(reason: EndReason = .ownerEnd) {
        guard state != .ended else { return }
        state = .ended
        broadcast(.sessionEnded(reason: reason), from: ownerID)
        transports.values.forEach { $0.close() }
        transports.removeAll()
    }

    // MARK: State machine (SPEC-RELAY §4.3)

    public func ownerDisconnected() {
        guard state == .active else { return }
        state = .suspended
        suspendedAt = now()
        transports.removeValue(forKey: ownerID)
        broadcast(.suspended, from: "relay")
    }

    public func ownerReconnected() -> MockRelayTransport? {
        checkTimeout()
        guard state == .suspended else { return nil } // ended → too late
        state = .active
        suspendedAt = nil
        let t = attach(memberID: ownerID)
        broadcast(.resumed, from: "relay")
        return t
    }

    /// The DO alarm — tests drive it through the injectable clock.
    public func checkTimeout() {
        if state == .suspended, let at = suspendedAt,
           now().timeIntervalSince(at) > Self.suspendTimeout {
            endSession(reason: .timeout)
        }
    }

    /// Replay for short reconnects (ring buffer, in-session only).
    public func framesSince(_ sinceSeq: UInt64) -> [Envelope] {
        buffer.filter { $0.seq > sinceSeq }
    }

    // MARK: Frame handling

    fileprivate func receive(_ frame: Frame, from memberID: MemberID) {
        checkTimeout()
        guard state != .ended, let member = members[memberID] else { return }
        switch frame {
        case .update:
            // APP-AC-06: role enforced AT THE RELAY, not in UI.
            guard member.role != .viewer else {
                transports[memberID]?.deliver(Envelope(seq: seq, from: "relay",
                    frame: .err(code: RelayErrorCode.forbiddenRole)))
                return
            }
            guard state == .active else { return } // suspended: client buffers locally
            broadcast(frame, from: memberID, excluding: memberID)
        case .presence:
            broadcast(frame, from: memberID, excluding: memberID) // viewers included
        case .snapshotReq:
            // Ask the owner (first editor-capable member) to provide it.
            if let provider = transports.first(where: { members[$0.key]?.role != .viewer })?.value {
                provider.deliver(Envelope(seq: seq, from: memberID, frame: .snapshotReq))
            }
        case .snapshot(let bytes):
            broadcast(.snapshot(bytes: bytes), from: memberID, excluding: memberID)
        case .ping(let nonce):
            transports[memberID]?.deliver(Envelope(seq: seq, from: "relay", frame: .pong(nonce: nonce)))
        default:
            break
        }
    }

    fileprivate func memberDisconnected(_ memberID: MemberID) {
        guard state != .ended else { return }
        if memberID == ownerID { ownerDisconnected(); return }
        transports.removeValue(forKey: memberID)
        broadcast(.memberLeft(memberID), from: "relay")
    }

    // MARK: - Private

    private func attach(memberID: MemberID) -> MockRelayTransport {
        let t = MockRelayTransport(hub: self, memberID: memberID)
        transports[memberID] = t
        return t
    }

    private func broadcast(_ frame: Frame, from: MemberID, excluding: MemberID? = nil) {
        seq += 1
        let env = Envelope(seq: seq, from: from, frame: frame)
        buffer.append(env)
        if buffer.count > Self.bufferSize { buffer.removeFirst(buffer.count - Self.bufferSize) }
        for (id, t) in transports where id != excluding {
            t.deliver(env)
        }
    }
}

/// One member's connection to the hub.
public final class MockRelayTransport: CollabTransport {
    public var onEnvelope: ((Envelope) -> Void)?
    public let memberID: MemberID
    private weak var hub: MockRelayHub?
    private(set) var isOpen = true

    init(hub: MockRelayHub, memberID: MemberID) {
        self.hub = hub
        self.memberID = memberID
    }

    public func send(_ frame: Frame) {
        guard isOpen else { return }
        hub?.receive(frame, from: memberID)
    }

    public func disconnect() {
        guard isOpen else { return }
        isOpen = false
        hub?.memberDisconnected(memberID)
    }

    func close() { isOpen = false }

    func deliver(_ env: Envelope) {
        guard isOpen else { return }
        onEnvelope?(env)
    }
}
