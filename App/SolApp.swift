import SwiftUI
import SolDesignSystem
import SolStore
import SolWorkspace
import SolEditor

@main
struct SolApp: App {
    init() {
        SolFontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Bootstraps the workspace (APP-FR-15: iCloud or local fallback) and composes
/// S1 → S2 navigation (plan §2.3: packages stay decoupled; the app is the glue).
private struct RootView: View {
    enum BootState {
        case loading
        case ready(WorkspaceViewModel)
        case failed(String)
    }

    @State private var state: BootState = .loading
    @State private var path: [Document] = []

    var body: some View {
        switch state {
        case .loading:
            ProgressView().task {
                do { state = .ready(try WorkspaceViewModel.bootstrap()) }
                catch { state = .failed(error.localizedDescription) }
            }
        case .ready(let model):
            NavigationStack(path: $path) {
                WorkspaceView(model: model) { doc in path.append(doc) }
                    .navigationDestination(for: Document.self) { doc in
                        editor(for: doc, store: model.store)
                            .onDisappear { model.refreshList() }
                    }
                    .toolbar(.hidden, for: .navigationBar)
            }
        case .failed(let message):
            ContentUnavailableView(
                "Không mở được workspace",
                systemImage: "exclamationmark.triangle",
                description: Text(message))
        }
    }

    @ViewBuilder
    private func editor(for doc: Document, store: DocumentStore) -> some View {
        if let model = try? EditorViewModel(store: store, document: doc,
                                            actor: UIDevice.current.name) {
            EditorView(model: model)
        } else {
            ContentUnavailableView("Không mở được tài liệu", systemImage: "doc.questionmark")
        }
    }
}
