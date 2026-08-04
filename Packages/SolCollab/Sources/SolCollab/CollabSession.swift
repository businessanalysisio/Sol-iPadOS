import Foundation
import Observation

/// Client-side Live Share session — APP-FR-13. Owns the CRDT replica and the
/// transport; encodes the PRD state-machine semantics on the client half:
/// - ACTIVE + editor/owner: local edits broadcast as `update` frames
/// - SUSPENDED: local edits buffer in `heldOps`; owner return replays them
///   through normal updates (EMMA-R-01)
/// - ENDED (any reason): the replica becomes a local read-only snapshot WITH
///   held ops applied — no keystroke is lost (G2 / APP-BR-01)
/// - viewer: edits rejected locally AND at the relay (defense in depth)
@Observable
public final class CollabSession {
    public enum EditError: Error, Equatable {
        case viewerCannotEdit
        case sessionEnded
    }

    public private(set) var doc: TextCRDT
    public private(set) var members: [Member] = []
    public private(set) var state: SessionState = .active
    public private(set) var role: MemberRole
    public private(set) var latencyMs: Int?
    /// Set exactly once when the session ends: the read-only local snapshot.
    public private(set) var endSnapshot: String?
    public private(set) var endReason: EndReason?
    /// Ops made while SUSPENDED — replayed on resume, folded into the
    /// snapshot on END.
    private(set) var heldOps: [CRDTOp] = []

    private let transport: CollabTransport
    private var lastSeq: UInt64 = 0

    public init(memberID: MemberID, displayName: String, role: MemberRole,
                transport: CollabTransport) {
        self.role = role
        self.transport = transport
        doc = TextCRDT(actor: memberID)
        transport.onEnvelope = { [weak self] env in self?.handle(env) }
    }

    public var text: String { doc.text }

    // MARK: Local edits

    @discardableResult
    public func insert(_ grapheme: String, at index: Int) -> Result<Void, EditError> {
        guard endSnapshot == nil else { return .failure(.sessionEnded) }
        guard role != .viewer else { return .failure(.viewerCannotEdit) }
        let op = doc.localInsert(grapheme, atVisible: index)
        dispatch(op)
        return .success(())
    }

    @discardableResult
    public func delete(at index: Int) -> Result<Void, EditError> {
        guard endSnapshot == nil else { return .failure(.sessionEnded) }
        guard role != .viewer else { return .failure(.viewerCannotEdit) }
        guard let op = doc.localDelete(atVisible: index) else { return .success(()) }
        dispatch(op)
        return .success(())
    }

    public func sendPresence(anchor: Int, length: Int) {
        transport.send(.presence(anchor: anchor, length: length))
    }

    public func leave() {
        transport.disconnect()
    }

    private func dispatch(_ op: CRDTOp) {
        if state == .suspended {
            heldOps.append(op) // giữ local, replay khi resume (APP-FR-13)
        } else {
            transport.send(.update(bytes: CRDTCoding.encode([op])))
        }
    }

    // MARK: Incoming frames

    private func handle(_ env: Envelope) {
        lastSeq = max(lastSeq, env.seq)
        switch env.frame {
        case .welcome(let members, let state, _):
            self.members = members
            self.state = state
            transport.send(.snapshotReq)
        case .snapshot(let bytes), .update(let bytes):
            CRDTCoding.decode(bytes).forEach(doc.apply)
        case .snapshotReq:
            transport.send(.snapshot(bytes: CRDTCoding.encode(doc.snapshotOps())))
        case .memberJoined(let m):
            members.removeAll { $0.id == m.id }
            members.append(m)
        case .memberLeft(let id):
            members.removeAll { $0.id == id }
        case .roleChanged(let id, let newRole):
            if let i = members.firstIndex(where: { $0.id == id }) { members[i].role = newRole }
            if id == doc.actor { role = newRole }
        case .suspended:
            state = .suspended
        case .resumed:
            state = .active
            let replay = heldOps
            heldOps.removeAll()
            if !replay.isEmpty {
                transport.send(.update(bytes: CRDTCoding.encode(replay)))
            }
        case .sessionEnded(let reason):
            // Held ops are already in the local replica (applied at edit
            // time) — the snapshot naturally contains them (G2).
            state = .ended
            endReason = reason
            endSnapshot = doc.text
        case .pong:
            latencyMs = latencyMs ?? 0 // real RTT measured on device (Layer 2)
        case .err(let code) where code == RelayErrorCode.forbiddenRole:
            break // defense-in-depth: local guard already prevents this path
        default:
            break
        }
    }
}
