import SwiftUI
import SolBootcamp
import SolStore
import SolDesignSystem

/// Màn S1 — Workspace (mockups v3). APP-FR-01/03/04/05.
public struct WorkspaceView: View {
    @State private var model: WorkspaceViewModel
    /// App layer composes navigation (plan §2.3: packages stay decoupled) —
    /// tapping a card hands the Document up instead of pushing a view here.
    private let onOpen: (Document) -> Void

    public init(model: WorkspaceViewModel, onOpen: @escaping (Document) -> Void = { _ in }) {
        _model = State(initialValue: model)
        self.onOpen = onOpen
    }

    @Environment(\.openWindow) private var openWindow

    private var chipState: SolSyncState {
        switch model.chipDot {
        case .upToDate: .synced
        case .syncing: .syncing
        case .offline: .offline
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            SolAppBar(title: "Sol Workspace", crumb: nil) {
                SolStatusChip(model.chipText, state: chipState)
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

            // APP-FR-11: conflict banners — always name the copy file; "Xem
            // bản sao" opens original here + copy in a NEW window (the M-01
            // official resolve flow rides APP-FR-02 multi-window).
            ForEach(model.conflicts) { event in
                SolConflictBanner(
                    message: (try? AttributedString(markdown:
                        "**Xung đột iCloud:** thiết bị của \(event.actorName) đã sửa file này. Bản của bạn được giữ; bản kia lưu thành **“\(event.copy.url.lastPathComponent)”** — mọi phiên bản phát hiện được đều được bảo toàn."))
                        ?? AttributedString("Xung đột iCloud: \(event.copy.url.lastPathComponent)"),
                    primaryAction: ("Xem bản sao", {
                        openWindow(value: event.copy)
                        onOpen(event.original)
                        model.dismissConflict(event)
                    }),
                    dismissAction: ("Đóng", { model.dismissConflict(event) })
                )
                .padding(.horizontal, Sol.Spacing.l).padding(.top, Sol.Spacing.s)
            }

            listTools
            documentArea
        }
        .background(SolColor.bg)
        .sheet(isPresented: $model.trashVisible) { TrashView(model: model) }
        .sheet(isPresented: $model.bootcampVisible) {
            // Board sửa Backlog/Dashboard trên cùng store — refresh khi đóng
            // để danh sách S1 thấy modifiedAt mới.
            BootcampBoardView(store: model.store)
                .onDisappear { model.refreshList() }
        }
        .sheet(isPresented: $model.learnVisible) {
            // Learn ghi Curriculum trên cùng store — refresh khi đóng để S1
            // thấy modifiedAt mới; "Mở trong Editor" đóng sheet rồi hand off
            // Document cho app layer như mọi cú mở tài liệu khác.
            LearnView(store: model.store) { doc in
                model.learnVisible = false
                onOpen(doc)
            }
            .onDisappear { model.refreshList() }
        }
        .sheet(isPresented: $model.settingsVisible) {
            SettingsView(settings: model.settings) { model.trashVisible = true }
        }
        .sheet(item: $model.versionHistoryDoc) { doc in
            // Khôi phục ghi lại file trên cùng store — refresh khi đóng để
            // danh sách S1 thấy modifiedAt mới.
            VersionHistoryView(store: model.store, document: doc)
                .onDisappear { model.refreshList() }
        }
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
            if model.learnAvailable {
                Button { model.learnVisible = true } label: { Image(systemName: "graduationcap") }
                    .foregroundStyle(SolColor.textSecondary)
                    .accessibilityLabel("Mở Bootcamp Learn")
            }
            if model.bootcampAvailable {
                Button { model.bootcampVisible = true } label: { Image(systemName: "checklist") }
                    .foregroundStyle(SolColor.textSecondary)
                    .accessibilityLabel("Mở Bootcamp Board")
            }
            Button { model.trashVisible = true } label: { Image(systemName: "trash") }
                .foregroundStyle(SolColor.textSecondary)
                .accessibilityLabel("Mở Thùng rác")
            Button { model.settingsVisible = true } label: { Image(systemName: "gearshape") }
                .foregroundStyle(SolColor.textSecondary)
                .keyboardShortcut(",", modifiers: .command) // ⌘, — Phụ lục A
                .accessibilityLabel("Mở Settings")
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
                        Button { onOpen(doc) } label: {
                            SolDocumentCard(
                                fileTag: doc.isConflictCopy ? ".MD · BẢN SAO XUNG ĐỘT" : ".MD",
                                title: doc.title,
                                meta: doc.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Mở trong cửa sổ mới") { openWindow(value: doc) }
                            Button("Lịch sử phiên bản") { model.versionHistoryDoc = doc }
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
