import SwiftUI
import SolDesignSystem

@main
struct SolApp: App {
    init() {
        SolFontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            // M0: design-system gallery is the app shell.
            // M1 replaces this with the Workspace scene (APP-FR-01/03/04/05).
            DesignSystemGallery()
        }
    }
}
