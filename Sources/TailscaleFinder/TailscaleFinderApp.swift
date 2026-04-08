import SwiftUI
import AppKit

@main
struct TailscaleFinderApp: App {
    init() {
        // Ensure the app appears as a regular GUI app with a dock icon and window
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 600, height: 700)
    }
}
