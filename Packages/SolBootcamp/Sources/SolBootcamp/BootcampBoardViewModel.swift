import Foundation
import Observation
import SolStore

/// View-model của Bootcamp Board: đọc Backlog từ DocumentStore, đổi status
/// bằng mutation phẫu thuật trên .md, rồi tái sinh Dashboard.
///
/// Ghi file theo đúng bất biến G2 của editor (journal-before-write): journal
/// ghi nhận TRƯỚC, save sau, clear cuối — kill app giữa chừng không mất gì.
/// Mỗi lần đổi status cũng ghi 1 version (actor = thiết bị, operation .edit)
/// nên lịch sử APP-FR-12 kể được "ai đổi, lúc nào".
@Observable
public final class BootcampBoardViewModel {
    public struct TrackSection: Identifiable {
        public var id: String { name }
        public let name: String
        public let items: [BacklogItem]
    }

    public private(set) var sections: [TrackSection] = []
    public private(set) var totalItems = 0
    public private(set) var doneItems = 0
    public private(set) var totalEffort = 0
    public private(set) var doneEffort = 0
    public var errorMessage: String?

    private let store: DocumentStore
    private let actor: String
    private var backlogDoc: Document?

    public init(store: DocumentStore, actor: String = "iPad") {
        self.store = store
        self.actor = actor
        reload()
    }

    /// Tìm tài liệu Backlog theo dòng H1 (rename-safe). N nhỏ ở M1 —
    /// cùng khẩu vị với sidecar reverse-lookup trong DocumentStore.
    public static func backlogDocument(in store: DocumentStore) -> Document? {
        (try? store.listDocuments())?.first { doc in
            (try? store.contents(of: doc))?.hasPrefix(BacklogDocument.marker) == true
        }
    }

    public var progress: Double {
        totalItems == 0 ? 0 : Double(doneItems) / Double(totalItems)
    }

    public func reload() {
        backlogDoc = Self.backlogDocument(in: store)
        guard let doc = backlogDoc, let text = try? store.contents(of: doc) else {
            sections = []
            totalItems = 0; doneItems = 0; totalEffort = 0; doneEffort = 0
            return
        }
        let items = BacklogDocument.parse(text)
        var names: [String] = []
        var byTrack: [String: [BacklogItem]] = [:]
        for item in items {
            if byTrack[item.track] == nil { names.append(item.track) }
            byTrack[item.track, default: []].append(item)
        }
        sections = names.map { TrackSection(name: $0, items: byTrack[$0] ?? []) }
        totalItems = items.count
        doneItems = items.filter { $0.status == .done }.count
        totalEffort = items.reduce(0) { $0 + $1.effortDays }
        doneEffort = items.filter { $0.status == .done }.reduce(0) { $0 + $1.effortDays }
    }

    /// Đổi status 1 item: sửa Backlog (chỉ 1 dòng) + tái sinh Dashboard.
    public func setStatus(_ status: BacklogStatus, for id: String) {
        guard let doc = backlogDoc, let text = try? store.contents(of: doc) else { return }
        let updated = BacklogDocument.settingStatus(in: text, id: id, to: status)
        guard updated != text else { return }
        do {
            try write(updated, to: doc)
            try refreshDashboard(items: BacklogDocument.parse(updated))
            errorMessage = nil
        } catch {
            errorMessage = "Không lưu được thay đổi — journal vẫn giữ nội dung."
        }
        reload()
    }

    // MARK: - Private

    private func write(_ content: String, to doc: Document) throws {
        try store.journal.recordPending(docID: doc.id, content: content)
        try store.save(doc, contents: content)
        store.journal.clearPending(docID: doc.id)
        try store.versions.record(docID: doc.id, content: content,
                                  actor: actor, operation: .edit)
    }

    /// Dashboard: ghi đè tài liệu có H1 khớp; người dùng đã xóa thì tạo lại
    /// (đây là output dẫn xuất từ Backlog, không phải nội dung gốc của họ).
    private func refreshDashboard(items: [BacklogItem]) throws {
        let content = DashboardRenderer.render(items: items)
        let existing = (try? store.listDocuments())?.first { doc in
            (try? store.contents(of: doc))?.hasPrefix(DashboardRenderer.marker) == true
        }
        if let doc = existing {
            try write(content, to: doc)
        } else {
            _ = try store.createDocument(named: "BA Bootcamp — 03 · Dashboard",
                                         contents: content)
        }
    }
}
