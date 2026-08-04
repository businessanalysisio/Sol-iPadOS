import SwiftUI
import SolStore
import SolDesignSystem

/// Màn S1 — Workspace (mockups v3). APP-FR-01/03/04/05.
public struct WorkspaceView: View {
    @State private var model: WorkspaceViewModel

    public init(model: WorkspaceViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SolAppBar(title: "Sol Workspace", crumb: model.chipText.isEmpty ? nil : nil) {
                SolStatusChip(model.chipText, state: .synced)
                Button("⌘K") { model.paletteVisible.toggle() }
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                    .keyboardShortcut("k", modifiers: .command)
                    .accessibilityLabel("Mở bảng lệnh")
                Button("+ Tài liệu mới") { model.newDocument() }
                    .buttonStyle(SolPrimaryButtonStyle())
                    .keyboardShortcut("n", modifiers: .command)
            }

            if let notice = model.fallbackNotice {
                Text(notice)
                    .font(SolFont.label()).foregroundStyle(SolColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Sol.Spacing.m)
                    .background(SolColor.warningTint)
            }

            listTools
            documentArea
        }
        .background(SolColor.bg)
        .sheet(isPresented: $model.trashVisible) { TrashView(model: model) }
        .overlay {
            if model.paletteVisible {
                CommandPaletteView(model: model)
            }
        }
        .overlay(alignment: .bottom) {
            if let error = model.errorMessage {
                SolToast(error).padding(.bottom, Sol.Spacing.l)
            }
        }
    }

    private var listTools: some View {
        HStack(spacing: Sol.Spacing.s) {
            Text("\(model.documents.count) tài liệu")
                .font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
            Spacer()
            TextField("Tìm trong workspace…", text: $model.query)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)
                .font(SolFont.body())
                .accessibilityLabel("Tìm trong workspace")
            SolSegmentedControl(options: ["Lưới", "Danh sách"], selection: Binding(
                get: { model.layout == .grid ? 0 : 1 },
                set: { model.layout = $0 == 0 ? .grid : .list }
            ))
            Button { model.trashVisible = true } label: { Image(systemName: "trash") }
                .foregroundStyle(SolColor.textSecondary)
                .accessibilityLabel("Mở Thùng rác")
        }
        .padding(.horizontal, Sol.Spacing.l).padding(.vertical, Sol.Spacing.m)
    }

    @ViewBuilder
    private var documentArea: some View {
        if model.documents.isEmpty {
            EmptyStateView(query: model.query) { model.newDocument() }
        } else {
            ScrollView {
                let columns = model.layout == .grid
                    ? [GridItem(.adaptive(minimum: 180), spacing: Sol.Spacing.m)]
                    : [GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: Sol.Spacing.m) {
                    ForEach(model.documents) { doc in
                        SolDocumentCard(fileTag: ".MD",
                                        title: doc.title,
                                        meta: doc.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                            .contextMenu {
                                Button("Xóa (vào Thùng rác)", role: .destructive) {
                                    model.softDelete(doc)
                                }
                            }
                    }
                }
                .padding(Sol.Spacing.l)
            }
        }
    }
}

/// Empty state — dot-grid brand decoration (design.md §5: max one per screen,
/// never behind body text).
struct EmptyStateView: View {
    let query: String
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Sol.Spacing.m) {
            Text(query.isEmpty ? "Chưa có tài liệu nào" : "Không tìm thấy tài liệu")
                .font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
            Text(query.isEmpty
                 ? "Bấm “+ Tài liệu mới” hoặc ⌘N để bắt đầu."
                 : "Thử từ khóa khác, hoặc tạo tài liệu mới cho “\(query)”.")
                .font(SolFont.body()).foregroundStyle(SolColor.textSecondary)
            Button("+ Tài liệu mới") { onCreate() }.buttonStyle(SolPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DotGrid().opacity(0.35))
    }
}

struct DotGrid: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 18
            for x in stride(from: step, to: size.width, by: step) {
                for y in stride(from: step, to: size.height, by: step) {
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)),
                                 with: .color(Color(hex: 0xD85A0B).opacity(0.35)))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
