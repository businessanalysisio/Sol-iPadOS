import SwiftUI
import SolDesignSystem

/// ⌘K command palette — APP-FR-05, closed list from Phụ lục A (SolCommandID).
/// Commands shipping in later milestones render disabled, never hidden (G3).
struct CommandPaletteView: View {
    @Bindable var model: WorkspaceViewModel
    @State private var filter = ""
    @FocusState private var focused: Bool

    private var commands: [SolCommandID] {
        let all = SolCommandID.allCases
        let folded = filter.lowercased()
        return folded.isEmpty ? all : all.filter { $0.title.lowercased().contains(folded) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture { model.paletteVisible = false }

            VStack(spacing: 0) {
                TextField("Gõ lệnh… (tài liệu, thùng rác)", text: $filter)
                    .textFieldStyle(.plain)
                    .font(SolFont.body())
                    .padding(Sol.Spacing.m)
                    .focused($focused)
                    .onSubmit(runFirst)
                    .onKeyPress(.escape) { // Esc đóng overlay (Phụ lục A)
                        model.paletteVisible = false
                        return .handled
                    }
                Divider().overlay(SolColor.border)

                ForEach(commands) { cmd in
                    Button { run(cmd) } label: {
                        HStack {
                            Text(cmd.title).font(SolFont.body())
                                .foregroundStyle(cmd.availableInM1 ? SolColor.textPrimary : SolColor.textSecondary)
                            Spacer()
                            if !cmd.availableInM1 {
                                Text("M2+").font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                            }
                            if let key = cmd.shortcutLabel {
                                Text(key).font(SolFont.data()).foregroundStyle(SolColor.textSecondary)
                            }
                        }
                        .padding(.horizontal, Sol.Spacing.m).padding(.vertical, Sol.Spacing.s)
                    }
                    .disabled(!cmd.availableInM1)
                }
                .padding(.vertical, Sol.Spacing.xs)
            }
            .frame(maxWidth: 380)
            .background(SolColor.surface, in: RoundedRectangle(cornerRadius: Sol.Radius.sheet))
            .shadow(color: .black.opacity(Sol.Elevation.overlayOpacity),
                    radius: Sol.Elevation.overlayRadius / 2, y: Sol.Elevation.overlayY)
            .padding(.top, 60)
            .onAppear { focused = true }
        }
    }

    private func runFirst() {
        if let first = commands.first(where: \.availableInM1) { run(first) }
    }

    private func run(_ cmd: SolCommandID) {
        model.paletteVisible = false
        switch cmd {
        case .newDocument: model.newDocument()
        case .openTrash: model.trashVisible = true
        case .findInWorkspace: break // focus moves to the S1 search field
        case .insertTable, .insertDataBlock, .exportSnapshot, .paneMode, .findInDocument:
            break // disabled until their milestone — unreachable via UI
        }
    }
}
