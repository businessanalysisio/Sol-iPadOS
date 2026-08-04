import SwiftUI
import SolDesignSystem
import SolWorkspace

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

/// Bootstraps the workspace (APP-FR-15: iCloud or local fallback) and renders
/// màn S1. Bootstrap failure is surfaced, never swallowed (G3).
private struct RootView: View {
    enum BootState {
        case loading
        case ready(WorkspaceViewModel)
        case failed(String)
    }

    @State private var state: BootState = .loading

    var body: some View {
        switch state {
        case .loading:
            ProgressView().task {
                do { state = .ready(try WorkspaceViewModel.bootstrap()) }
                catch { state = .failed(error.localizedDescription) }
            }
        case .ready(let model):
            WorkspaceView(model: model)
        case .failed(let message):
            ContentUnavailableView(
                "Không mở được workspace",
                systemImage: "exclamationmark.triangle",
                description: Text(message))
        }
    }
}
