import SwiftUI
import SolBlockModel
import SolStore
import SolDesignSystem

/// Màn S2 — Editor (APP-FR-06/07/08/12).
public struct EditorView: View {
    @State private var model: EditorViewModel
    @State private var selection = NSRange(location: 0, length: 0)
    @State private var fragments: [LineFragment] = []
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase

    public init(model: EditorViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 0) {
            SolAppBar(title: model.document.title + ".md") {
                SolStatusChip(model.saveState == .saved ? "Đã lưu cục bộ" : "Chưa lưu — journal ghi nhận",
                              state: .synced)
                SolSegmentedControl(options: ["Soạn thảo", "Song song", "Preview"], selection: Binding(
                    get: { model.paneMode.rawValue },
                    set: { model.paneMode = .init(rawValue: $0) ?? .both }
                ))
            }

            HStack(spacing: 0) {
                if model.paneMode != .preview {
                    editorPane
                    if model.paneMode == .both {
                        Divider().overlay(SolColor.border)
                    }
                }
                if model.paneMode != .editor {
                    PreviewView(blocks: model.blockDoc.result.blocks,
                                resolveCSV: { model.resolveCSV($0) })
                }
            }

            toolbar
        }
        .background(SolColor.surface)
        // ⌘1/2/3 — Phụ lục A "Chuyển chế độ pane"
        .background {
            Group {
                Button("") { model.paneMode = .editor }.keyboardShortcut("1", modifiers: .command)
                Button("") { model.paneMode = .both }.keyboardShortcut("2", modifiers: .command)
                Button("") { model.paneMode = .preview }.keyboardShortcut("3", modifiers: .command)
            }.hidden()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive { model.flush() }
        }
        .onDisappear { model.flush() }
        .overlay(alignment: .bottom) {
            if let error = model.errorMessage {
                SolToast(error).padding(.bottom, Sol.Spacing.l)
            }
        }
    }

    private var editorPane: some View {
        HStack(spacing: 0) {
            GutterView(lineTypes: model.blockDoc.result.lineTypes,
                       fragments: fragments,
                       scrollOffset: scrollOffset)
            MarkdownTextView(
                text: Binding(get: { model.text }, set: { model.setText($0) }),
                onSelectionChange: { selection = $0 },
                onScroll: { scrollOffset = $0 },
                onFragments: { fragments = $0 })
        }
    }

    /// Toolbar — APP-FR-08 (mockup v2: B / I / H₂ / ≔ / ❝ / ▦ Bảng).
    private var toolbar: some View {
        HStack(spacing: Sol.Spacing.xs) {
            key("B") { model.wrapSelection(selection, with: "**") }
                .keyboardShortcut("b", modifiers: .command)
            key("I") { model.wrapSelection(selection, with: "*") }
                .keyboardShortcut("i", modifiers: .command)
            key("H₂") { model.prefixCurrentLine(selection, with: "## ") }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            key("≔") { model.prefixCurrentLine(selection, with: "- ") }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            key("❝") { model.prefixCurrentLine(selection, with: "> ") }
                .keyboardShortcut("q", modifiers: [.command, .shift])
            key("▦ Bảng") { model.insertTable() }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            Spacer()
            Button("Xuất snapshot") { model.exportSnapshot() }
                .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
        }
        .padding(.horizontal, Sol.Spacing.m)
        .frame(height: Sol.Chrome.toolbar)
        .background(SolColor.surfaceAlt)
        .overlay(alignment: .top) { Divider().overlay(SolColor.border) }
    }

    private func key(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(SolFont.data()).foregroundStyle(SolColor.textPrimary)
                .padding(.horizontal, 6).frame(minWidth: 26, minHeight: 24)
                .background(SolColor.surface, in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(SolColor.border))
        }
        .accessibilityLabel(label == "B" ? "In đậm" : label == "I" ? "In nghiêng" : label)
    }
}
