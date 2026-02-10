import Cocoa
import SwiftUI

class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem!
    private weak var coordinator: AppCoordinator?
    private var menu: NSMenu!
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        super.init()
        setupStatusItem()
        setupMenu()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.circle.fill", accessibilityDescription: "DevDeck")
            button.action = #selector(statusBarClicked(_:))
            button.target = self
            // Listen for both left and right clicks
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
        // Items
        let showOverlayItem = NSMenuItem(title: "Show Overlay", action: #selector(showOverlay), keyEquivalent: "")
        showOverlayItem.target = self
        menu.addItem(showOverlayItem)
        
        let dashboardItem = NSMenuItem(title: "Dashboard...", action: #selector(openDashboard), keyEquivalent: "")
        dashboardItem.target = self
        menu.addItem(dashboardItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let importItem = NSMenuItem(title: "Import Backup...", action: #selector(importBackup), keyEquivalent: "")
        importItem.target = self
        menu.addItem(importItem)
        
        let exportItem = NSMenuItem(title: "Export Backup...", action: #selector(exportBackup), keyEquivalent: "")
        exportItem.target = self
        menu.addItem(exportItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        // Debug
        print("Status Bar Clicked. Event Type: \(String(describing: event?.type))")
        
        if event?.type == .rightMouseUp || (event?.type == .leftMouseUp && event?.modifierFlags.contains(.control) == true) {
            // Show Menu
            print("Showing Menu")
            statusItem.menu = menu 
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
            statusItem.menu = nil // Clear menu so subsequent left clicks work as action
        } else {
            // Left Click -> Show Overlay
            print("Showing Overlay")
            coordinator?.showOverlayManually()
        }
    }
    
    // Actions
    @objc private func showOverlay() {
        coordinator?.showOverlayManually()
    }
    
    @objc private func openDashboard() {
        // Open dashboard via URL scheme to ensure SwiftUI Window appears
        if let url = URL(string: "devdeck://dashboard") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func importBackup() {
        ImportExportManager.shared.presentImportPanel()
    }
    
    @objc private func exportBackup() {
        ImportExportManager.shared.presentExportPanel()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
