import SwiftUI
import SolDesignSystem
import SolStore
import SolWorkspace
import SolEditor

/// Shared services across window scenes — multi-window (APP-FR-02) needs the
/// same store behind every window, so bootstrap exactly once.
final class AppServices {
    static let shared = AppServices()
    private var cached: Result<WorkspaceViewModel, Error>?

    func workspace() -> Result<WorkspaceViewModel, Error> {
        if let cached { return cached }
        let result = Result { try WorkspaceViewModel.bootstrap() }
        cached = result
        return result
    }
}

@main
struct SolApp: App {
    init() {
        SolFontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // Second scene type: one document per window. "Mở trong cửa sổ mới"
        // and the conflict resolve flow (M-01) open documents here — two
        // windows side-by-side in Split View is the official compare UX.
        WindowGroup(for: Document.self) { $doc in
            if let doc {
                DocumentWindow(document: doc)
            }
        }
    }
}

/// Main window: Workspace (S1) with push navigation to the editor (S2).
private struct RootView: View {
    @State private var bootResult = AppServices.shared.workspace()
    @State private var path: [Document] = []

    var body: some View {
        switch bootResult {
        case .success(let model):
            NavigationStack(path: $path) {
                WorkspaceView(model: model) { doc in path.append(doc) }
                    .navigationDestination(for: Document.self) { doc in
                        EditorScreen(document: doc, store: model.store)
                            .onDisappear { model.refreshList() }
                    }
                    .toolbar(.hidden, for: .navigationBar)
            }
        case .failure(let error):
            ContentUnavailableView(
                "Không mở được workspace",
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription))
        }
    }
}

/// Standalone document window (secondary scenes).
private struct DocumentWindow: View {
    let document: Document

    var body: some View {
        switch AppServices.shared.workspace() {
        case .success(let model):
            EditorScreen(document: document, store: model.store)
        case .failure(let error):
            ContentUnavailableView(
                "Không mở được workspace",
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription))
        }
    }
}

/// Fail-safe editor wrapper shared by both scene types.
struct EditorScreen: View {
    let document: Document
    let store: DocumentStore

    var body: some View {
        if let model = try? EditorViewModel(store: store, document: document,
                                            actor: UIDevice.current.name) {
            EditorView(model: model)
        } else {
            ContentUnavailableView("Không mở được tài liệu", systemImage: "doc.questionmark")
        }
    }
}
