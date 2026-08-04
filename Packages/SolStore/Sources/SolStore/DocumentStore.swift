import Foundation

/// A markdown document in the workspace. Identity = stable UUID kept in a
/// sidecar (survives rename/move); the file itself stays a plain `.md` any
/// app can open (APP-FR-10).
public struct Document: Identifiable, Equatable, Hashable {
    public let id: String
    public var url: URL
    public var title: String { url.deletingPathExtension().lastPathComponent }
    public var modifiedAt: Date
}

/// An entry in the Trash — APP-FR-17.
public struct TrashItem: Identifiable, Equatable, Codable {
    public let id: String
    public let originalName: String
    public let deletedAt: Date
    public var expiresAt: Date { deletedAt.addingTimeInterval(30 * 24 * 3600) }
}

public enum DocumentStoreError: Error, Equatable {
    case documentNotFound
    case quotaExceeded          // maps NSFileWriteOutOfSpace → ICloudStatus.quotaFull UX
    case fileTooLarge(limit: Int) // APP-BR-02: .md ≤ 10 MB
}

/// File-based document store with soft-delete, purge cascade and search index.
/// All destructive paths keep a recovery route (APP-NFR-02):
/// delete → Trash (30 days) → purge cascades content + index (+ journal/version in M2+).
public final class DocumentStore {
    public static let maxFileBytes = 10 * 1024 * 1024 // APP-BR-02
    public static let untitledName = "Tài liệu chưa đặt tên"

    public let root: URL
    public let journal: JournalStore   // APP-FR-12: journal-before-write
    public let versions: VersionStore  // APP-FR-12: version history + metadata
    private let trashDir: URL
    private let idsDir: URL // sidecar: <uuid> file containing relative path
    private let index: SearchIndex
    private let fm: FileManager
    private let now: () -> Date

    /// `now` is injectable so the 30-day purge is deterministic in tests.
    public init(root: URL, index: SearchIndex,
                fileManager: FileManager = .default,
                now: @escaping () -> Date = Date.init) throws {
        self.root = root
        self.trashDir = root.appendingPathComponent(".sol-trash", isDirectory: true)
        self.idsDir = root.appendingPathComponent(".sol-ids", isDirectory: true)
        self.index = index
        self.fm = fileManager
        self.now = now
        self.journal = try JournalStore(workspaceRoot: root, fileManager: fileManager)
        self.versions = try VersionStore(workspaceRoot: root, fileManager: fileManager, now: now)
        for dir in [root, trashDir, idsDir] {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        // Best-effort auto-purge at open — APP-BR-04: "first app open after 30 days".
        try? purgeExpired()
    }

    // MARK: Create / save (APP-FR-01: ≤ 2 thao tác — one call, no dialogs)

    @discardableResult
    public func createDocument(named name: String = DocumentStore.untitledName,
                               contents: String = "") throws -> Document {
        let url = FileNaming.collisionFreeURL(for: "\(name).md", in: root, fileManager: fm)
        let id = UUID().uuidString
        try write(contents, to: url)
        try fm.createDirectory(at: idsDir, withIntermediateDirectories: true)
        try id.write(to: sidecar(for: url), atomically: true, encoding: .utf8)
        try index.index(docID: id, title: titleOf(url), body: contents)
        return Document(id: id, url: url, modifiedAt: now())
    }

    public func save(_ doc: Document, contents: String) throws {
        try write(contents, to: doc.url)
        try index.index(docID: doc.id, title: titleOf(doc.url), body: contents)
    }

    public func rename(_ doc: Document, to newName: String) throws -> Document {
        let dest = FileNaming.collisionFreeURL(for: "\(newName).md", in: doc.url.deletingLastPathComponent(), fileManager: fm)
        let oldSidecar = sidecar(for: doc.url)
        try fm.moveItem(at: doc.url, to: dest)
        try? fm.moveItem(at: oldSidecar, to: sidecar(for: dest))
        let body = (try? String(contentsOf: dest, encoding: .utf8)) ?? ""
        try index.index(docID: doc.id, title: titleOf(dest), body: body)
        return Document(id: doc.id, url: dest, modifiedAt: now())
    }

    // MARK: List / read

    public func listDocuments() throws -> [Document] {
        let urls = try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter { $0.pathExtension == "md" }
        return try urls.map { url in
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? now()
            return Document(id: try docID(for: url), url: url, modifiedAt: modified)
        }
        .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    public func contents(of doc: Document) throws -> String {
        try String(contentsOf: doc.url, encoding: .utf8)
    }

    public func search(_ text: String) throws -> [Document] {
        let ids = try index.search(text)
        let all = try listDocuments()
        let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    // MARK: Trash — APP-FR-17

    public func softDelete(_ doc: Document) throws {
        let meta = TrashItem(id: doc.id, originalName: doc.url.lastPathComponent, deletedAt: now())
        try fm.moveItem(at: doc.url, to: trashDir.appendingPathComponent("\(doc.id).md"))
        let data = try JSONEncoder().encode(meta)
        try data.write(to: trashDir.appendingPathComponent("\(doc.id).json"))
        try? fm.removeItem(at: sidecarByID(doc.id))
        // Soft-deleted docs leave search results immediately; content is still
        // recoverable from the Trash for 30 days.
        try index.remove(docID: doc.id)
    }

    public func listTrash() throws -> [TrashItem] {
        let decoder = JSONDecoder()
        return try fm.contentsOfDirectory(at: trashDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(TrashItem.self, from: Data(contentsOf: $0)) }
            .sorted { $0.deletedAt > $1.deletedAt }
    }

    /// Restore keeps content + falls back to the APP-FR-03 suffix rule on collision.
    @discardableResult
    public func restore(_ item: TrashItem) throws -> Document {
        let src = trashDir.appendingPathComponent("\(item.id).md")
        guard fm.fileExists(atPath: src.path) else { throw DocumentStoreError.documentNotFound }
        let dest = FileNaming.collisionFreeURL(for: item.originalName, in: root, fileManager: fm)
        try fm.moveItem(at: src, to: dest)
        try? fm.removeItem(at: trashDir.appendingPathComponent("\(item.id).json"))
        try item.id.write(to: sidecar(for: dest), atomically: true, encoding: .utf8)
        let body = (try? String(contentsOf: dest, encoding: .utf8)) ?? ""
        try index.index(docID: item.id, title: titleOf(dest), body: body)
        return Document(id: item.id, url: dest, modifiedAt: now())
    }

    /// Purge cascade — APP-BR-04 / APP-AC-08: content, index entry, sidecar,
    /// journal, and every version. After this, nothing of the doc is reachable.
    public func purge(_ item: TrashItem) throws {
        try? fm.removeItem(at: trashDir.appendingPathComponent("\(item.id).md"))
        try? fm.removeItem(at: trashDir.appendingPathComponent("\(item.id).json"))
        try? fm.removeItem(at: sidecarByID(item.id))
        try index.remove(docID: item.id)
        journal.purgeAll(docID: item.id)
        versions.purgeAll(docID: item.id)
    }

    /// "Xuất snapshot" (Phụ lục A / APP-FR-12): named version + a read-only
    /// copy in Snapshots/ the user can share from Files.app.
    @discardableResult
    public func exportSnapshot(of doc: Document, actor: String) throws -> URL {
        let content = try contents(of: doc)
        try versions.record(docID: doc.id, content: content, actor: actor, operation: .snapshot)
        let snapDir = root.appendingPathComponent("Snapshots", isDirectory: true)
        try fm.createDirectory(at: snapDir, withIntermediateDirectories: true)
        // Filename-safe stamp (Localization §9: filenames always ISO-ordered,
        // no "/" or ":"): yyyy-MM-dd-HHmmss.
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        let name = "\(doc.title)-snapshot-\(f.string(from: now())).md"
        let dest = FileNaming.collisionFreeURL(for: name, in: snapDir, fileManager: fm)
        try Data(content.utf8).write(to: dest, options: .atomic)
        return dest
    }

    /// Best-effort: purges everything older than 30 days. Called at store open.
    public func purgeExpired() throws {
        for item in try listTrash() where item.expiresAt <= now() {
            try purge(item)
        }
    }

    // MARK: - Private

    private func write(_ contents: String, to url: URL) throws {
        let data = Data(contents.utf8)
        guard data.count <= Self.maxFileBytes else {
            throw DocumentStoreError.fileTooLarge(limit: Self.maxFileBytes)
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch let e as NSError where e.code == NSFileWriteOutOfSpaceError {
            throw DocumentStoreError.quotaExceeded
        }
    }

    private func titleOf(_ url: URL) -> String { url.deletingPathExtension().lastPathComponent }

    private func sidecar(for url: URL) -> URL {
        idsDir.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".id")
    }

    private func sidecarByID(_ id: String) -> URL {
        // Reverse lookup: scan sidecars for the matching id (small N; fine for M1).
        let files = (try? fm.contentsOfDirectory(at: idsDir, includingPropertiesForKeys: nil)) ?? []
        for f in files where (try? String(contentsOf: f, encoding: .utf8)) == id { return f }
        return idsDir.appendingPathComponent("\(id).id.missing")
    }

    private func docID(for url: URL) throws -> String {
        let sc = sidecar(for: url)
        if let id = try? String(contentsOf: sc, encoding: .utf8) { return id }
        // Self-heal: file appeared outside the app (iCloud, Files.app) — adopt it.
        let id = UUID().uuidString
        try id.write(to: sc, atomically: true, encoding: .utf8)
        let body = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        try index.index(docID: id, title: titleOf(url), body: body)
        return id
    }
}
