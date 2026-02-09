import SwiftUI
import AppKit
import ApplicationServices

@main
struct DevDeckApp: App {
    @StateObject var coordinator = AppCoordinator()
    
    var body: some Scene {
        Window("Macro Manager", id: "dashboard") {
            MacroManagerView(profileManager: coordinator.profileManager)
        }
        .defaultSize(width: 1000, height: 800)
        
        MenuBarExtra("DevDeck", systemImage: "circle.circle.fill") {
            MenuBarView(coordinator: coordinator)
        }
    }
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [trusted: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            print("Access Not Trusted! Prompting user...")
        }
    }
}

struct MenuBarView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        Button("Show Overlay") {
            coordinator.showOverlayManually()
        }
        Button("Dashboard...") {
            openWindow(id: "dashboard")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
