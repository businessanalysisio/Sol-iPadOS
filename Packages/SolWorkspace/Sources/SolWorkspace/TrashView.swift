import SwiftUI
import SolStore
import SolDesignSystem

/// Thùng rác — APP-FR-17. Restore về vị trí cũ (suffix rule khi trùng tên);
/// xóa vĩnh viễn luôn qua hộp xác nhận (APP-BR-04).
struct TrashView: View {
    @Bindable var model: WorkspaceViewModel
    @State private var confirmingPurge: TrashItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if model.trashItems.isEmpty {
                    Text("Thùng rác trống")
                        .font(SolFont.body()).foregroundStyle(SolColor.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(model.trashItems) { item in
                        HStack(spacing: Sol.Spacing.m) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.originalName)
                                    .font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
                                Text("Xóa \(item.deletedAt.formatted(date: .abbreviated, time: .omitted)) · tự dọn sau \(item.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                            }
                            Spacer()
                            Button("Khôi phục") { model.restore(item) }
                                .buttonStyle(SolPrimaryButtonStyle())
                            Button(role: .destructive) { confirmingPurge = item } label: {
                                Text("Xóa vĩnh viễn").font(SolFont.labelStrong())
                            }
                        }
                        .listRowBackground(SolColor.surface)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(SolColor.bg)
            .navigationTitle("Thùng rác")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .confirmationDialog(
                "Xóa vĩnh viễn “\(confirmingPurge?.originalName ?? "")”?",
                isPresented: Binding(get: { confirmingPurge != nil },
                                     set: { if !$0 { confirmingPurge = nil } }),
                titleVisibility: .visible
            ) {
                Button("Xóa vĩnh viễn — không thể hoàn tác", role: .destructive) {
                    if let item = confirmingPurge { model.purge(item) }
                    confirmingPurge = nil
                }
                Button("Hủy", role: .cancel) { confirmingPurge = nil }
            } message: {
                Text("Nội dung, chỉ mục tìm kiếm và mọi dấu vết của tài liệu sẽ bị xóa (APP-BR-04).")
            }
        }
    }
}
