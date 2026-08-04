import Foundation
import Observation
import SolBlockModel
import SolStore

/// Màn S2 state machine: text ↔ BlockDocument ↔ journal/autosave.
///
/// Save pipeline per keystroke (G2 ordering is the invariant):
///   text change → reparse → journal.recordPending (200ms debounce)
///               → store.save + clearPending      (900ms debounce)
/// The journal write ALWAYS lands before the save that clears it.
@Observable
public final class EditorViewModel {
    public enum PaneMode: Int { case editor = 0, both = 1, preview = 2 }
    public enum SaveState: Equatable {
        case saved                  // "Đã lưu cục bộ"
        case journaled              // "Chưa lưu — journal ghi nhận"
    }

    public private(set) var document: Document
    public private(set) var blockDoc: BlockDocument
    public private(set) var saveState: SaveState = .saved
    public var paneMode: PaneMode = .both
    public var errorMessage: String?

    private let store: DocumentStore
    private let actor: String
    private var journalTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?

    /// Debounce intervals are injectable so tests run without sleeping.
    private let journalDelay: Duration
    private let saveDelay: Duration

    public init(store: DocumentStore, document: Document, actor: String = "iPad",
                journalDelay: Duration = .milliseconds(200),
                saveDelay: Duration = .milliseconds(900)) throws {
        self.store = store
        self.document = document
        self.actor = actor
        self.journalDelay = journalDelay
        self.saveDelay = saveDelay

        // Crash recovery (G2): a pending journal newer than the file wins.
        let fileContent = try store.contents(of: document)
        if let pending = store.journal.pending(docID: document.id), pending != fileContent {
            blockDoc = BlockDocument(text: pending)
            saveState = .journaled // recovered but not yet saved — chip stays honest
        } else {
            blockDoc = BlockDocument(text: fileContent)
        }
    }

    public var text: String { blockDoc.text }

    /// Single entry point for edits (typing, toolbar, paste).
    public func setText(_ newText: String) {
        blockDoc.replaceAll(with: newText)
        saveState = .journaled
        scheduleJournal()
        scheduleSave()
    }

    // MARK: Toolbar — APP-FR-08 (operates on the raw text; the view supplies
    // the selected UTF-16 range from UITextView)

    public func wrapSelection(_ range: NSRange, with marker: String) {
        let ns = text as NSString
        guard range.location != NSNotFound, NSMaxRange(range) <= ns.length else { return }
        let selected = ns.substring(with: range)
        let replaced = ns.replacingCharacters(in: range, with: marker + selected + marker)
        setText(replaced)
    }

    public func prefixCurrentLine(_ range: NSRange, with prefix: String) {
        let ns = text as NSString
        guard range.location != NSNotFound, range.location <= ns.length else { return }
        let lineRange = ns.lineRange(for: NSRange(location: range.location, length: 0))
        setText(ns.replacingCharacters(in: NSRange(location: lineRange.location, length: 0), with: prefix))
    }

    public func insertTable() {
        setText(text + "\n\n| Cột A | Cột B | Cột C |\n|---|---|---|\n| … | … | … |")
    }

    // MARK: Lifecycle

    /// Flush everything now (scene background / editor close). Also records a
    /// version checkpoint — the APP-FR-12 metadata floor.
    public func flush() {
        journalTask?.cancel(); saveTask?.cancel()
        do {
            try store.journal.recordPending(docID: document.id, content: text)
            try store.save(document, contents: text)
            store.journal.clearPending(docID: document.id)
            try store.versions.record(docID: document.id, content: text, actor: actor, operation: .edit)
            saveState = .saved
        } catch {
            errorMessage = "Không lưu được: \(error.localizedDescription) — nội dung vẫn còn trong journal."
        }
    }

    public func exportSnapshot() {
        flush()
        do { _ = try store.exportSnapshot(of: document, actor: actor) }
        catch { errorMessage = "Không xuất được snapshot: \(error.localizedDescription)" }
    }

    /// Resolves a sol-data `src=` path relative to the workspace root
    /// (APP-FR-09: "liên kết file data/*.csv"). Rejects escapes above root.
    public func resolveCSV(_ path: String) -> String? {
        let target = store.root.appendingPathComponent(path).standardizedFileURL
        guard target.path.hasPrefix(store.root.standardizedFileURL.path) else { return nil }
        return try? String(contentsOf: target, encoding: .utf8)
    }

    // MARK: Debounced pipeline

    private func scheduleJournal() {
        journalTask?.cancel()
        journalTask = Task { [journalDelay] in
            try? await Task.sleep(for: journalDelay)
            guard !Task.isCancelled else { return }
            try? store.journal.recordPending(docID: document.id, content: text)
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [saveDelay] in
            try? await Task.sleep(for: saveDelay)
            guard !Task.isCancelled else { return }
            do {
                // Journal first (in case the debounces raced), then save.
                try store.journal.recordPending(docID: document.id, content: text)
                try store.save(document, contents: text)
                store.journal.clearPending(docID: document.id)
                await MainActor.run { saveState = .saved }
            } catch {
                await MainActor.run {
                    errorMessage = "Không lưu được — journal vẫn giữ nội dung."
                }
            }
        }
    }
}
