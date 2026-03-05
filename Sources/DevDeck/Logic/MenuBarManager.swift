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
            button.image = makeMenuBarIcon()
            button.action = #selector(statusBarClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    /// Renders the app icon into a fresh 18×18 image using CGContext,
    /// which works without a screen drawing context (safe at app launch).
    private func makeMenuBarIcon() -> NSImage {
        let pt: Int = 18
        let scale: Int = 2                     // render at 2× for clarity on Retina
        let px = pt * scale

        // Load source — never touch NSApp.applicationIconImage directly
        guard let source = NSImage(named: NSImage.applicationIconName),
              let cgSource = source.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            // Safe fallback: use an SF Symbol template (never corrupts)
            return NSImage(systemSymbolName: "square.stack.3d.up.fill",
                           accessibilityDescription: "DevDeck")
                   ?? NSImage()
        }

        let colorSpace  = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo  = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let ctx = CGContext(data: nil,
                                  width: px, height: px,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue),
              let result = { ctx.draw(cgSource, in: CGRect(x: 0, y: 0, width: px, height: px)); return ctx.makeImage() }()
        else {
            return NSImage(systemSymbolName: "square.stack.3d.up.fill",
                           accessibilityDescription: "DevDeck") ?? NSImage()
        }

        let icon = NSImage(cgImage: result, size: NSSize(width: pt, height: pt))
        return icon
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
