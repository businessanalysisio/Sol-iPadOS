import Foundation

/// Journal-before-write — APP-FR-12 / G2. The editor writes the pending
/// content here (debounced, atomic) BEFORE the main file is saved; if the app
/// dies mid-edit, the next open recovers the journal. "Kill app giữa lúc gõ →
/// mở lại không mất ký tự" is tested against this store.
public final class JournalStore {
    private let dir: URL
    private let fm: FileManager

    public init(workspaceRoot: URL, fileManager: FileManager = .default) throws {
        dir = workspaceRoot.appendingPathComponent(".sol-journal", isDirectory: true)
        fm = fileManager
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func url(_ docID: String) -> URL { dir.appendingPathComponent("\(docID).pending") }

    /// Atomic write: a crash mid-record leaves the previous journal intact.
    public func recordPending(docID: String, content: String) throws {
        try Data(content.utf8).write(to: url(docID), options: .atomic)
    }

    /// Non-nil ⇒ the app died before the last save landed.
    public func pending(docID: String) -> String? {
        guard let data = try? Data(contentsOf: url(docID)) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    /// Called ONLY after the main file write succeeded.
    public func clearPending(docID: String) {
        try? fm.removeItem(at: url(docID))
    }

    /// Purge cascade hook (APP-BR-04): a purged document's journal goes too.
    public func purgeAll(docID: String) {
        clearPending(docID: docID)
    }
}

/// Version history with the v1 auditability floor — APP-FR-12 (DAVID-01):
/// every version carries actor / timestamp / operation.
public struct VersionMeta: Codable, Equatable, Hashable, Identifiable {
    public enum Operation: String, Codable { case edit, restore, conflictCopy, importExternal, snapshot }
    public let id: String
    public let docID: String
    public let actor: String
    public let timestamp: Date
    public let operation: Operation
}

public final class VersionStore {
    private let dir: URL
    private let fm: FileManager
    private let now: () -> Date

    public init(workspaceRoot: URL, fileManager: FileManager = .default,
                now: @escaping () -> Date = Date.init) throws {
        dir = workspaceRoot.appendingPathComponent(".sol-versions", isDirectory: true)
        fm = fileManager
        self.now = now
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func docDir(_ docID: String) -> URL { dir.appendingPathComponent(docID, isDirectory: true) }

    @discardableResult
    public func record(docID: String, content: String, actor: String,
                       operation: VersionMeta.Operation) throws -> VersionMeta {
        let meta = VersionMeta(id: UUID().uuidString, docID: docID,
                               actor: actor, timestamp: now(), operation: operation)
        let d = docDir(docID)
        try fm.createDirectory(at: d, withIntermediateDirectories: true)
        try Data(content.utf8).write(to: d.appendingPathComponent("\(meta.id).md"), options: .atomic)
        try JSONEncoder().encode(meta).write(to: d.appendingPathComponent("\(meta.id).json"), options: .atomic)
        return meta
    }

    public func list(docID: String) throws -> [VersionMeta] {
        let d = docDir(docID)
        guard fm.fileExists(atPath: d.path) else { return [] }
        let decoder = JSONDecoder()
        return try fm.contentsOfDirectory(at: d, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(VersionMeta.self, from: Data(contentsOf: $0)) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    public func content(of version: VersionMeta) throws -> String {
        try String(contentsOf: docDir(version.docID).appendingPathComponent("\(version.id).md"),
                   encoding: .utf8)
    }

    /// Purge cascade hook (APP-BR-04): all versions of a purged doc are removed.
    public func purgeAll(docID: String) {
        try? fm.removeItem(at: docDir(docID))
    }
}
