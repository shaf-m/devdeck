import SwiftUI
import AppKit
import ApplicationServices

// MARK: - App Delegate

class DevDeckAppDelegate: NSObject, NSApplicationDelegate {
    /// Keep the app alive even when all windows are closed
    /// (the overlay and menu bar icon should remain active).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - App Entry Point

@main
struct DevDeckApp: App {
    @NSApplicationDelegateAdaptor(DevDeckAppDelegate.self) var appDelegate
    @StateObject var coordinator = AppCoordinator()

    var body: some Scene {
        Window("Macro Manager", id: "dashboard") {
            MacroManagerView(
                profileManager: coordinator.profileManager,
                clipboardManager: coordinator.clipboardManager
            )
        }
        .defaultSize(width: 1000, height: 800)
        .handlesExternalEvents(matching: ["dashboard"])
    }
}
