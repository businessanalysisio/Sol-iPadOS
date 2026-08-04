import Foundation

/// Wire types mirroring SPEC-RELAY §4 exactly. The mock hub AND the future
/// CloudflareCollabTransport speak these frames — one protocol, two backends
/// (APP-NFR-06). Field names match the spec so A3 can use this file as the
/// reference schema.

public typealias MemberID = String
public typealias SessionID = String

public enum MemberRole: String, Codable, Equatable {
    case owner, editor, viewer
}

public enum SessionState: String, Codable, Equatable {
    case active, suspended, ended
}

public struct Member: Codable, Equatable, Identifiable {
    public var id: MemberID
    public var displayName: String
    public var role: MemberRole

    public init(id: MemberID, displayName: String, role: MemberRole) {
        self.id = id
        self.displayName = displayName
        self.role = role
    }
}

public enum EndReason: String, Codable, Equatable {
    case ownerEnd = "owner_end"
    case timeout
}

/// SPEC-RELAY §4.2 frames. Envelope carries {t, seq, from, payload} — here
/// modeled as an enum whose associated values are the payloads.
public enum Frame: Codable, Equatable {
    case hello(token: String)
    case welcome(members: [Member], state: SessionState, sinceSeq: UInt64)
    /// CRDT delta — opaque bytes to the relay (it never decodes them).
    case update(bytes: Data)
    case snapshotReq
    case snapshot(bytes: Data)
    case presence(anchor: Int, length: Int)
    case roleChanged(member: MemberID, role: MemberRole)
    case memberJoined(Member)
    case memberLeft(MemberID)
    case suspended
    case resumed
    case sessionEnded(reason: EndReason)
    case ping(nonce: UInt64)
    case pong(nonce: UInt64)
    case err(code: String)
}

public struct Envelope: Codable, Equatable {
    public let seq: UInt64
    public let from: MemberID
    public let frame: Frame

    public init(seq: UInt64, from: MemberID, frame: Frame) {
        self.seq = seq
        self.from = from
        self.frame = frame
    }
}

/// Error codes the relay may return (SPEC-RELAY §4.2 / §4.1).
public enum RelayErrorCode {
    public static let forbiddenRole = "FORBIDDEN_ROLE" // viewer sent update (APP-AC-06)
    public static let gone = "GONE"                    // join after END → app shows "Phiên đã kết thúc"
    public static let linkRevoked = "LINK_REVOKED"     // join after revoke (new joins only)
}

/// Typed join failures (REST layer, SPEC-RELAY §4.1).
public enum RelayJoinError: Error, Equatable {
    case gone        // 410 — "Phiên đã kết thúc"
    case linkRevoked // link vô hiệu, phiên vẫn chạy cho người bên trong
}

/// Client-side transport abstraction — mock in tests/Layer 1, Cloudflare DO
/// in v1.1 production. Deliberately tiny: connect, send, receive, close.
public protocol CollabTransport: AnyObject {
    var onEnvelope: ((Envelope) -> Void)? { get set }
    func send(_ frame: Frame)
    func disconnect()
}

public enum CRDTCoding {
    public static func encode(_ ops: [CRDTOp]) -> Data {
        (try? JSONEncoder().encode(ops)) ?? Data()
    }
    public static func decode(_ data: Data) -> [CRDTOp] {
        (try? JSONDecoder().decode([CRDTOp].self, from: data)) ?? []
    }
}
