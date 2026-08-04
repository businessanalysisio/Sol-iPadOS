import Foundation

/// A version of a document that conflicts with the local one (surfaced by
/// NSFileVersion on device, or constructed directly in Layer-1 tests).
public struct ConflictingVersion: Equatable {
    public let actorName: String   // "Hảo" / device name that saved it
    public let modifiedAt: Date
    public let content: String

    public init(actorName: String, modifiedAt: Date, content: String) {
        self.actorName = actorName
        self.modifiedAt = modifiedAt
        self.content = content
    }
}

/// Outcome of one resolved conflict — feeds the banner (which must name the
/// copy file, design.md §6) and the multi-window resolve flow (M-01).
public struct ConflictEvent: Identifiable, Equatable {
    public let id: String
    public let original: Document
    public let copy: Document
    public let actorName: String
}

public extension Document {
    /// M-01: conflicted copies carry a badge and group under their original.
    var isConflictCopy: Bool { title.contains("(conflicted copy ") }
}

/// ADR-A02 executor: NEVER merges, never picks a winner. The local file stays
/// byte-identical; the conflicting version becomes a sibling file named per
/// APP-BR-03 — "<tên> (conflicted copy <người> <yyyy-MM-dd>).md", numeric
/// suffix on repeat collision. Every step is Layer-1 testable (ADR-A03).
public final class ConflictResolver {
    private let store: DocumentStore

    public init(store: DocumentStore) {
        self.store = store
    }

    @discardableResult
    public func resolve(original: Document, conflicting: ConflictingVersion) throws -> ConflictEvent {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd" // filename stays ISO + EN cross-locale (APP-BR-03)
        let copyName = "\(original.title) (conflicted copy \(conflicting.actorName) \(f.string(from: conflicting.modifiedAt)))"

        // createDocument applies the APP-FR-03 suffix rule on repeat conflicts
        // and indexes the copy so it is immediately searchable (badged, M-01).
        let copy = try store.createDocument(named: copyName, contents: conflicting.content)

        // Audit trail on the ORIGINAL: a conflict happened here (APP-FR-12).
        try store.versions.record(docID: original.id,
                                  content: conflicting.content,
                                  actor: conflicting.actorName,
                                  operation: .conflictCopy)

        return ConflictEvent(id: copy.id, original: original, copy: copy,
                             actorName: conflicting.actorName)
    }
}
