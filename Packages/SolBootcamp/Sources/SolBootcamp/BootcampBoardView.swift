import SwiftUI
import SolStore
import SolDesignSystem

/// Bootcamp Board — bộ Backlog dưới dạng bảng điều khiển: chạm để đổi
/// status, Dashboard tự tính lại. Trình bày trong sheet từ màn S1.
/// Chỉ dùng token SolColor/SolFont/Sol.* (APP-BR-05).
public struct BootcampBoardView: View {
    @State private var model: BootcampBoardViewModel

    public init(store: DocumentStore, actor: String = "iPad") {
        _model = State(initialValue: BootcampBoardViewModel(store: store, actor: actor))
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if model.sections.isEmpty {
                emptyState
            } else {
                board
            }
        }
        .background(SolColor.bg)
        .overlay(alignment: .bottom) {
            if let error = model.errorMessage {
                SolToast(error).padding(.bottom, Sol.Spacing.l)
            }
        }
    }

    // MARK: - Header (tiến độ tổng)

    private var header: some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.s) {
            HStack(spacing: Sol.Spacing.s) {
                Text("Bootcamp OS")
                    .font(SolFont.h1()).foregroundStyle(SolColor.textPrimary)
                Spacer()
                Text("\(model.doneItems)/\(model.totalItems) items · \(model.doneEffort)/\(model.totalEffort) ngày")
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
            }
            ProgressView(value: model.progress)
                .tint(SolColor.accent)
                .accessibilityLabel("Tiến độ Bootcamp")
                .accessibilityValue("\(model.doneItems) trên \(model.totalItems) hạng mục xong")
        }
        .padding(.horizontal, Sol.Spacing.l)
        .padding(.vertical, Sol.Spacing.m)
        .background(SolColor.surface)
    }

    private var emptyState: some View {
        VStack(spacing: Sol.Spacing.m) {
            Text("Không tìm thấy Backlog")
                .font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
            Text("Board cần tài liệu có dòng đầu “\(BacklogDocument.marker)”. Khôi phục từ Thùng rác nếu bạn đã xóa.")
                .font(SolFont.body()).foregroundStyle(SolColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Sol.Spacing.xl)
    }

    // MARK: - Board

    private var board: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Sol.Spacing.m, pinnedViews: .sectionHeaders) {
                ForEach(model.sections) { section in
                    Section {
                        ForEach(section.items) { item in
                            BacklogRow(item: item) { model.setStatus($0, for: item.id) }
                        }
                    } header: {
                        Text(section.name)
                            .font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, Sol.Spacing.s)
                            .background(SolColor.bg)
                    }
                }
            }
            .padding(.horizontal, Sol.Spacing.l)
            .padding(.bottom, Sol.Spacing.xl)
        }
    }
}

/// Một dòng backlog: định danh + ngữ cảnh bên trái, nút status bên phải.
struct BacklogRow: View {
    let item: BacklogItem
    let onStatus: (BacklogStatus) -> Void

    var body: some View {
        HStack(spacing: Sol.Spacing.m) {
            VStack(alignment: .leading, spacing: Sol.Spacing.xxs) {
                HStack(spacing: Sol.Spacing.s) {
                    Text(item.id)
                        .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                    Text(item.title)
                        .font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
                        .lineLimit(2)
                }
                Text("\(item.sprint) · \(item.effortDays) ngày · \(item.priority) · \(item.owner)")
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Sol.Spacing.s)
            statusMenu
        }
        .padding(Sol.Spacing.m)
        .background(SolColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Sol.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Sol.Radius.card)
            .stroke(SolColor.border, lineWidth: 1))
    }

    private var statusMenu: some View {
        Menu {
            ForEach(BacklogStatus.allCases, id: \.rawValue) { status in
                Button {
                    onStatus(status)
                } label: {
                    if status == item.status {
                        Label(status.label, systemImage: "checkmark")
                    } else {
                        Text(status.label)
                    }
                }
            }
        } label: {
            Text(item.status.label)
                .font(SolFont.label())
                .foregroundStyle(color(for: item.status))
                .padding(.horizontal, Sol.Spacing.m)
                .padding(.vertical, Sol.Spacing.xs)
                .background(color(for: item.status).opacity(0.14))
                .clipShape(Capsule())
        }
        .accessibilityLabel("Trạng thái \(item.id)")
        .accessibilityValue(item.status.label)
    }

    /// Màu trạng thái từ semantic tokens (không hard-code — APP-BR-05).
    private func color(for status: BacklogStatus) -> Color {
        switch status {
        case .notStarted: SolColor.textSecondary
        case .inProgress: SolColor.accent
        case .blocked: SolColor.danger
        case .done: SolColor.positive
        }
    }
}
