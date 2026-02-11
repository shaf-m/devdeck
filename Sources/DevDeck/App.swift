import SwiftUI
import AppKit
import ApplicationServices

@main
struct DevDeckApp: App {
    @StateObject var coordinator = AppCoordinator()
    
    var body: some Scene {
        Window("Macro Manager", id: "dashboard") {
            MacroManagerView(profileManager: coordinator.profileManager, clipboardManager: coordinator.clipboardManager)
        }
        .defaultSize(width: 1000, height: 800)
        .handlesExternalEvents(matching: ["dashboard"])
        
    }
}
