import Cocoa
import SwiftUI

class OverlayWindow: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        // Ensure we include fullSizeContentView for true transparancy in some cases
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView], backing: backing, defer: flag)
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Critical Transparency Settings
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        
        self.ignoresMouseEvents = false // We want to click buttons
    }
    
    // Allow window to become key if needed for keyboard interactions, though .nonactivatingPanel usually prevents this for focus stealing.
    // For a productivity tool overlay, we often want it to *not* steal focus from the underlying app
    // but still accept mouse clicks.
    override var canBecomeKey: Bool {
        return true 
    }
}
