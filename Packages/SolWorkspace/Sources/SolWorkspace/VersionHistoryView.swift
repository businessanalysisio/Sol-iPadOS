import SwiftUI
import Observation
import SolStore
import SolDesignSystem

/// View-model của màn Lịch sử phiên bản (APP-FR-12, O10): đọc kho version
/// (ai · lúc nào · thao tác gì), xem nội dung từng bản, và khôi phục.
///
/// Khôi phục không bao giờ làm mất dữ liệu: nội dung HIỆN TẠI được ghi thành
/// một version `.edit` trước (nếu chưa có bản ghi trùng), rồi bản cũ mới được
/// ghi đè theo đúng bất biến G2 (journal-before-write) + version `.restore`.
@Observable
public final class VersionHistoryViewModel {
    public private(set) var versions: [VersionMeta] = []
    public let document: Document
    public var errorMessage: String?

    private let store: DocumentStore
    private let actor: String

    public init(store: DocumentStore, document: Document, actor: String = "iPad") {
        self.store = store
        self.document = document
        self.actor = actor
        reload()
    }

    public func reload() {
        versions = (try? store.versions.list(docID: document.id)) ?? [] // newest-first
    }

    public func content(of version: VersionMeta) -> String? {
        try? store.versions.content(of: version)
    }

    /// Khôi phục một phiên bản. Trả về true khi đã ghi thành công.
    @discardableResult
    public func restore(_ version: VersionMeta) -> Bool {
        guard let restored = try? store.versions.content(of: version),
              let current = try? store.contents(of: document) else {
            errorMessage = "Không đọc được phiên bản — file có thể đã bị xóa."
            return false
        }
        do {
            // Lưới an toàn: nội dung hiện tại chưa từng được version hóa
            // (đang gõ dở) thì ghi lại trước, để khôi phục là thao tác
            // hai-chiều — không có đường nào làm mất chữ của người dùng.
            let newestRecorded = versions.first.flatMap { try? store.versions.content(of: $0) }
            if current != restored, current != newestRecorded {
                try store.versions.record(docID: document.id, content: current,
                                          actor: actor, operation: .edit)
            }
            if current != restored {
                try store.journal.recordPending(docID: document.id, content: restored)
                try store.save(document, contents: restored)
                store.journal.clearPending(docID: document.id)
                try store.versions.record(docID: document.id, content: restored,
                                          actor: actor, operation: .restore)
            }
            errorMessage = nil
            reload()
            return true
        } catch {
            errorMessage = "Không khôi phục được — journal vẫn giữ nội dung."
            reload()
            return false
        }
    }
}

/// Nhãn tiếng Việt cho Operation — file giữ rawValue tiếng Anh (Codable),
/// UI dịch qua đây (cùng khẩu vị BacklogStatus/LessonStatus).
extension VersionMeta.Operation {
    var label: String {
        switch self {
        case .edit: "Soạn thảo"
        case .restore: "Khôi phục"
        case .conflictCopy: "Bản sao xung đột"
        case .importExternal: "Nhập từ ngoài"
        case .snapshot: "Snapshot"
        }
    }

    var icon: String {
        switch self {
        case .edit: "pencil"
        case .restore: "arrow.uturn.backward"
        case .conflictCopy: "exclamationmark.triangle"
        case .importExternal: "square.and.arrow.down"
        case .snapshot: "camera"
        }
    }
}

/// Màn Lịch sử phiên bản — sheet từ context menu của tài liệu ở S1.
/// Chỉ dùng token SolColor/SolFont/Sol.* (APP-BR-05).
public struct VersionHistoryView: View {
    @State private var model: VersionHistoryViewModel

    public init(store: DocumentStore, document: Document, actor: String = "iPad") {
        _model = State(initialValue: VersionHistoryViewModel(store: store, document: document,
                                                             actor: actor))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                if model.versions.isEmpty {
                    emptyState
                } else {
                    versionList
                }
            }
            .background(SolColor.bg)
            .navigationDestination(for: VersionMeta.self) { version in
                VersionDetailView(model: model, version: version)
            }
            .overlay(alignment: .bottom) {
                if let error = model.errorMessage {
                    SolToast(error).padding(.bottom, Sol.Spacing.l)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.xs) {
            Text("Lịch sử phiên bản")
                .font(SolFont.h1()).foregroundStyle(SolColor.textPrimary)
            Text("\(model.document.title) · \(model.versions.count) phiên bản")
                .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Sol.Spacing.l)
        .padding(.vertical, Sol.Spacing.m)
        .background(SolColor.surface)
    }

    private var emptyState: some View {
        VStack(spacing: Sol.Spacing.m) {
            Text("Chưa có phiên bản nào")
                .font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
            Text("Phiên bản được ghi mỗi lần lưu — sửa tài liệu rồi quay lại đây.")
                .font(SolFont.body()).foregroundStyle(SolColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Sol.Spacing.xl)
    }

    private var versionList: some View {
        ScrollView {
            LazyVStack(spacing: Sol.Spacing.m) {
                ForEach(model.versions) { version in
                    NavigationLink(value: version) {
                        VersionRow(version: version)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Sol.Spacing.l)
        }
    }
}

struct VersionRow: View {
    let version: VersionMeta

    var body: some View {
        HStack(spacing: Sol.Spacing.m) {
            Image(systemName: version.operation.icon)
                .foregroundStyle(version.operation == .conflictCopy
                                 ? SolColor.danger : SolColor.accent)
                .frame(width: Sol.Chrome.avatar)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Sol.Spacing.xxs) {
                Text(version.operation.label)
                    .font(SolFont.subheading()).foregroundStyle(SolColor.textPrimary)
                Text("\(version.actor) · \(version.timestamp.formatted(date: .abbreviated, time: .shortened))")
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
            }
            Spacer(minLength: Sol.Spacing.s)
            Image(systemName: "chevron.right")
                .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(Sol.Spacing.m)
        .background(SolColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Sol.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Sol.Radius.card)
            .stroke(SolColor.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(version.operation.label), \(version.actor), \(version.timestamp.formatted(date: .abbreviated, time: .shortened))")
    }
}

/// Xem nội dung một phiên bản + nút khôi phục (có xác nhận — dù restore đã
/// có lưới an toàn, ghi đè vẫn là hành động cần chủ ý).
struct VersionDetailView: View {
    let model: VersionHistoryViewModel
    let version: VersionMeta

    @State private var confirmingRestore = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Sol.Spacing.m) {
                VStack(alignment: .leading, spacing: Sol.Spacing.xxs) {
                    Text(version.operation.label)
                        .font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
                    Text("\(version.actor) · \(version.timestamp.formatted(date: .abbreviated, time: .shortened))")
                        .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                }
                Spacer()
                Button("Khôi phục phiên bản này") { confirmingRestore = true }
                    .buttonStyle(SolPrimaryButtonStyle())
            }
            .padding(Sol.Spacing.l)
            .background(SolColor.surface)

            ScrollView {
                Text(model.content(of: version) ?? "Không đọc được nội dung phiên bản.")
                    .font(SolFont.mono()).foregroundStyle(SolColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Sol.Spacing.l)
                    .textSelection(.enabled)
            }
        }
        .background(SolColor.bg)
        .confirmationDialog(
            "Khôi phục phiên bản này? Nội dung hiện tại được giữ lại thành một phiên bản Soạn thảo.",
            isPresented: $confirmingRestore, titleVisibility: .visible
        ) {
            Button("Khôi phục") {
                if model.restore(version) { dismiss() }
            }
            Button("Hủy", role: .cancel) {}
        }
    }
}
