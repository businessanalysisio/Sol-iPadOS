import Foundation
import Observation
import SolBootcamp
import SolStore

/// View-model for màn S1. Owns the store, search state and trash state.
@Observable
public final class WorkspaceViewModel {
    public enum Layout { case grid, list }

    public private(set) var documents: [Document] = []
    public private(set) var trashItems: [TrashItem] = []
    public private(set) var backing: WorkspaceLocation.Backing
    public private(set) var syncStatus: SyncStatus = .upToDate
    /// Unresolved conflict banners (APP-FR-11) — resolver already made the
    /// copies; these wait for the user to view or dismiss.
    public private(set) var conflicts: [ConflictEvent] = []
    public var layout: Layout = .grid
    public var query: String = "" { didSet { refreshList() } }
    public var paletteVisible = false
    public var trashVisible = false
    public var settingsVisible = false
    public var bootcampVisible = false
    public var learnVisible = false
    /// Tài liệu đang xem lịch sử phiên bản (APP-FR-12) — nil = sheet đóng.
    public var versionHistoryDoc: Document?
    /// Nút Bootcamp Board chỉ hiện khi workspace thật sự có tài liệu Backlog.
    public private(set) var bootcampAvailable = false
    /// Nút Bootcamp Learn chỉ hiện khi workspace thật sự có tài liệu Curriculum.
    public private(set) var learnAvailable = false
    public var errorMessage: String?

    /// Exposed so the app layer can hand the same store to the editor.
    public let store: DocumentStore
    /// App-wide preferences (APP-FR-16) — RootView reads theme from here.
    public let settings: SettingsStore
    private let syncEngine: SyncEngine?

    public init(store: DocumentStore, backing: WorkspaceLocation.Backing,
                syncEngine: SyncEngine? = nil,
                settings: SettingsStore = SettingsStore()) {
        self.store = store
        self.backing = backing
        self.syncEngine = syncEngine
        self.settings = settings
        if let engine = syncEngine {
            syncStatus = engine.status
            engine.onStatusChange = { [weak self] status in
                Task { @MainActor in self?.syncStatus = status }
            }
            engine.start()
        }
        refreshList()
    }

    /// Production entry point: resolve location (APP-FR-15), open store,
    /// attach the iCloud sync engine when the container backs the workspace.
    public static func bootstrap() throws -> WorkspaceViewModel {
        let local = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SolWorkspace", isDirectory: true)
        let location = try WorkspaceLocation.resolve(
            ubiquity: DefaultUbiquityProvider(), localRoot: local)
        // O13 (APP-FR-15/EMMA-R-03): phiên trước chạy fallback cục bộ mà nay
        // iCloud đã sẵn sàng → di trú copy-then-delete vào container TRƯỚC khi
        // mở store; đụng tên lấy hậu tố số, không bao giờ ghi đè.
        if case .iCloud = location.backing {
            WorkspaceLocation.migrateIfNeeded(localRoot: local, into: location.root)
        }
        let dbURL = location.root.appendingPathComponent(".sol-index.sqlite")
        let store = try DocumentStore(root: location.root, index: SearchIndex(databaseURL: dbURL))
        // First open only: seed the BA Bootcamp working set (SOL Bootcamp OS)
        // + the Learn curriculum. Markers are separate so a workspace seeded
        // before Bootcamp Learn shipped still receives the curriculum here.
        // Best-effort — a seeding failure must never block the workspace.
        try? BootcampSeed.installIfNeeded(into: store)
        try? LearnSeed.installIfNeeded(into: store)
        let engine: SyncEngine? = location.backing == .iCloud ? ICloudSyncEngine() : nil
        let telemetry = try? TelemetryLog(
            directory: location.root.appendingPathComponent(".sol-telemetry", isDirectory: true))
        return WorkspaceViewModel(store: store, backing: location.backing,
                                  syncEngine: engine,
                                  settings: SettingsStore(telemetry: telemetry))
    }

    // MARK: Conflicts (APP-FR-11 — banner + multi-window resolve, M-01)

    public func reportConflict(_ event: ConflictEvent) {
        conflicts.append(event)
        refreshList() // the copy is a new, badged document
    }

    public func dismissConflict(_ event: ConflictEvent) {
        conflicts.removeAll { $0.id == event.id }
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

    /// Sync chip — M4 unlocks the three real states (M-02 phase policy ends
    /// here). Still honest: local-fallback workspaces and engine-less iCloud
    /// never claim sync state they cannot verify (G3 / APP-AC-05).
    public var chipText: String {
        guard case .iCloud = backing, syncEngine != nil else { return "Đã lưu cục bộ" }
        switch syncStatus {
        case .upToDate: return "Đã đồng bộ"
        case .syncing(let n): return "Đang đồng bộ \(n) thay đổi…"
        case .offline: return "Ngoại tuyến — sẽ đồng bộ khi có mạng"
        }
    }

    /// Dot color state for SolStatusChip.
    public var chipDot: SyncStatus { syncEngine == nil ? .upToDate : syncStatus }

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
            bootcampAvailable = BootcampBoardViewModel.backlogDocument(in: store) != nil
            learnAvailable = LearnViewModel.curriculumDocument(in: store) != nil
        } catch DocumentStoreError.fileTooLarge(let limit) {
            errorMessage = "File vượt giới hạn \(limit / 1_048_576) MB (APP-BR-02). Hãy tách nhỏ tài liệu."
        } catch DocumentStoreError.quotaExceeded {
            errorMessage = "iCloud hết dung lượng — thay đổi được giữ cục bộ, sẽ đồng bộ khi có chỗ."
        } catch {
            errorMessage = "Có lỗi khi thao tác với tài liệu: \(error.localizedDescription)"
        }
    }
}
