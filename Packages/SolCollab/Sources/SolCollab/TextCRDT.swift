import Foundation

/// Operation identity: totally ordered by (counter, actor). Lamport-style —
/// counter bumps past every op an actor has seen, so causally-later ops
/// always compare greater.
public struct OpID: Hashable, Comparable, Codable {
    public let counter: UInt64
    public let actor: String

    public static func < (a: OpID, b: OpID) -> Bool {
        a.counter != b.counter ? a.counter < b.counter : a.actor < b.actor
    }
}

/// Text CRDT operation — the payload of relay `update` frames (opaque bytes
/// to the relay itself, SPEC-RELAY §4.2/§6).
public enum CRDTOp: Codable, Equatable {
    case insert(id: OpID, after: OpID?, text: String) // text = one grapheme
    case delete(target: OpID, by: OpID)
}

/// RGA (Replicated Growable Array) text CRDT — pure Swift, no binary deps.
///
/// Convergence argument (standard RGA, Attiya et al.): elements form a
/// sequence; an insert anchors after a parent element. Integration scans
/// right from the parent and skips elements with a GREATER OpID before
/// inserting, so concurrent siblings order by descending OpID identically on
/// every replica; deletes are tombstones and idempotent. The property tests
/// in CRDTConvergenceTests exercise this with adversarial orderings.
///
/// Production note (deliberate): this replaces the plan's Automerge option
/// for v1.1 — no XCFramework binary in CI, fully inspectable, sized for
/// plain-text markdown docs. Swappable behind CollabSession if scale ever
/// demands (APP-NFR-06 spirit).
public final class TextCRDT {
    struct Element {
        let id: OpID
        let text: String
        var deleted: Bool
    }

    public let actor: String
    private var counter: UInt64 = 0
    private var elements: [Element] = []
    private var seenInserts: Set<OpID> = []
    private var seenDeletes: Set<OpID> = []

    public init(actor: String) {
        self.actor = actor
    }

    public var text: String {
        elements.lazy.filter { !$0.deleted }.map(\.text).joined()
    }

    // MARK: Local edits (visible-index space) → ops to broadcast

    public func localInsert(_ grapheme: String, atVisible index: Int) -> CRDTOp {
        counter += 1
        let id = OpID(counter: counter, actor: actor)
        let after = elementID(beforeVisible: index)
        let op = CRDTOp.insert(id: id, after: after, text: grapheme)
        apply(op)
        return op
    }

    public func localDelete(atVisible index: Int) -> CRDTOp? {
        guard let target = elementID(atVisible: index) else { return nil }
        counter += 1
        let op = CRDTOp.delete(target: target, by: OpID(counter: counter, actor: actor))
        apply(op)
        return op
    }

    // MARK: Remote integration — idempotent, order-tolerant

    /// Ops whose causal dependency has not arrived yet (insert before its
    /// parent, delete before its target). Without this buffer, a shuffled
    /// delivery order silently mis-anchors ops and replicas diverge — the
    /// exact failure the 3-actor fuzz caught on CI.
    private var pendingOps: [CRDTOp] = []

    public func apply(_ op: CRDTOp) {
        guard integrate(op) else {
            pendingOps.append(op)
            return
        }
        // Newly-arrived op may unblock buffered ones — drain to fixpoint.
        var progressed = true
        while progressed {
            progressed = false
            for (i, p) in pendingOps.enumerated() where integrate(p) {
                pendingOps.remove(at: i)
                progressed = true
                break
            }
        }
    }

    /// Returns false when the op must wait for its causal dependency.
    /// "Seen" sets are only updated on success, so a deferred op is never
    /// swallowed.
    private func integrate(_ op: CRDTOp) -> Bool {
        switch op {
        case .insert(let id, let after, let text):
            guard !seenInserts.contains(id) else { return true }
            let anchor: Int
            if let after {
                guard let found = elements.firstIndex(where: { $0.id == after }) else { return false }
                anchor = found + 1
            } else {
                anchor = 0
            }
            seenInserts.insert(id)
            counter = max(counter, id.counter) // Lamport advance
            // RGA integration: concurrent siblings settle in descending OpID.
            // Sound because a greater sibling's whole subtree carries greater
            // IDs (Lamport: descendants outrank ancestors), so skipping never
            // crosses into a lesser sibling's territory.
            var idx = anchor
            while idx < elements.count, elements[idx].id > id { idx += 1 }
            elements.insert(Element(id: id, text: text, deleted: false), at: idx)
            return true
        case .delete(let target, let by):
            guard !seenDeletes.contains(by) else { return true }
            guard let idx = elements.firstIndex(where: { $0.id == target }) else { return false }
            seenDeletes.insert(by)
            counter = max(counter, by.counter)
            elements[idx].deleted = true
            return true
        }
    }

    /// All ops needed to reconstruct this replica — the `snapshot` payload a
    /// joining guest receives (SPEC-RELAY §4.2).
    public func snapshotOps() -> [CRDTOp] {
        var ops: [CRDTOp] = []
        var prev: OpID? = nil
        for e in elements {
            ops.append(.insert(id: e.id, after: prev, text: e.text))
            prev = e.id
        }
        // Tombstones re-marked with synthetic delete ids (already-seen guard
        // on the receiver keys by `by`, so reuse a stable derived id).
        for e in elements where e.deleted {
            ops.append(.delete(target: e.id, by: OpID(counter: e.id.counter, actor: "†" + e.id.actor)))
        }
        return ops
    }

    // MARK: - Visible-index helpers

    private func elementID(atVisible index: Int) -> OpID? {
        var seen = 0
        for e in elements where !e.deleted {
            if seen == index { return e.id }
            seen += 1
        }
        return nil
    }

    private func elementID(beforeVisible index: Int) -> OpID? {
        index == 0 ? nil : elementID(atVisible: index - 1)
    }
}
