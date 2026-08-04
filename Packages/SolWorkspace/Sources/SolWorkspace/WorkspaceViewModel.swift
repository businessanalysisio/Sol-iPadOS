import Foundation
import Observation
import SolStore

/// View-model for màn S1. Owns the store, search state and trash state.
@Observable
public final class WorkspaceViewModel {
    public enum Layout { case grid, list }

    public private(set) var documents: [Document] = []
    public private(set) var trashItems: [TrashItem] = []
    public private(set) var backing: WorkspaceLocation.Backing
    public var layout: Layout = .grid
    public var query: String = "" { didSet { refreshList() } }
    public var paletteVisible = false
    public var trashVisible = false
    public var errorMessage: String?

    private let store: DocumentStore

    public init(store: DocumentStore, backing: WorkspaceLocation.Backing) {
        self.store = store
        self.backing = backing
        refreshList()
    }

    /// Production entry point: resolve location (APP-FR-15), open store.
    public static func bootstrap() throws -> WorkspaceViewModel {
        let local = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SolWorkspace", isDirectory: true)
        let location = try WorkspaceLocation.resolve(
            ubiquity: DefaultUbiquityProvider(), localRoot: local)
        let dbURL = location.root.appendingPathComponent(".sol-index.sqlite")
        let store = try DocumentStore(root: location.root, index: SearchIndex(databaseURL: dbURL))
        return WorkspaceViewModel(store: store, backing: location.backing)
    }

    // MARK: Actions (each maps to a Phụ lục A command or S1 control)

    public func newDocument() {
        perform { _ = try store.createDocument() }
    }

    public func softDelete(_ doc: Document) {
        perform { try store.softDelete(doc) }
    }

    public func restore(_ item: TrashItem) {
        perform { _ = try store.restore(item) }
    }

    /// Permanent delete — only from the Trash screen, caller shows confirmation
    /// first (APP-BR-04).
    public func purge(_ item: TrashItem) {
        perform { try store.purge(item) }
    }

    public func refreshList() {
        perform {}
    }

    /// Sync chip per M-02: M1–M3 the chip only ever says "Đã lưu cục bộ"
    /// (never claims iCloud state it cannot verify — G3). M4 adds real states.
    public var chipText: String { "Đã lưu cục bộ" }

    /// Banner for local-fallback mode (APP-FR-15).
    public var fallbackNotice: String? {
        switch backing {
        case .iCloud: nil
        case .localFallback(.noAccount):
            "Chưa đăng nhập iCloud — đang dùng workspace cục bộ. Bật iCloud để đồng bộ."
        case .localFallback(.disabled):
            "iCloud Drive đang tắt cho Sol — đang dùng workspace cục bộ."
        case .localFallback(.quotaFull):
            "iCloud hết dung lượng — đang dùng workspace cục bộ."
        case .localFallback(.available):
            nil // unreachable by construction
        }
    }

    /// Runs a store mutation, then reloads list + trash. Errors map to the
    /// clear, actionable messages APP-BR-02 requires.
    private func perform(_ work: () throws -> Void) {
        do {
            try work()
            errorMessage = nil
            documents = query.trimmingCharacters(in: .whitespaces).isEmpty
                ? try store.listDocuments()
                : try store.search(query)
            trashItems = try store.listTrash()
        } catch DocumentStoreError.fileTooLarge(let limit) {
            errorMessage = "File vượt giới hạn \(limit / 1_048_576) MB (APP-BR-02). Hãy tách nhỏ tài liệu."
        } catch DocumentStoreError.quotaExceeded {
            errorMessage = "iCloud hết dung lượng — thay đổi được giữ cục bộ, sẽ đồng bộ khi có chỗ."
        } catch {
            errorMessage = "Có lỗi khi thao tác với tài liệu: \(error.localizedDescription)"
        }
    }
}
