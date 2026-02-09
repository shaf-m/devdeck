import Cocoa
import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var profileManager = ProfileManager()
    
    private var inputMonitor = GlobalInputMonitor()
    private var contextManager = ContextManager()
    
    private var overlayWindow: OverlayWindow?
    private var cancellables = Set<AnyCancellable>()
    
    private var shortcutMonitor: Any?
    
    init() {
        setupBindings()
        createWindow()
        setupShortcutMonitor()
    }
    
    // ... (rest of class)
    
    private func setupShortcutMonitor() {
        // Monitor local key presses when app is active (overlay is up)
        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.overlayWindow?.isVisible == true else { return event }
            
            // Checks for number keys 1-6
            // Use charactersIgnoringModifiers to handle "Cmd+1", "Shift+1" etc reliably
            if let chars = event.charactersIgnoringModifiers, let num = Int(chars), num >= 1 && num <= 6 {
                // Execute macro at index num-1
                if let macros = self.profileManager.activeProfile?.macros, num - 1 < macros.count {
                    let macro = macros[num - 1]
                    self.executeMacro(macro)
                    return nil // Swallow event
                }
            }
            // "Esc" to close
            if event.keyCode == 53 {
                self.hideOverlay()
                return nil
            }
            
            return event
        }
    }
    
    private func setupBindings() {
        // Bind Context (Bundle ID) -> Profile
        contextManager.$activeBundleId
            .sink { [weak self] bundleId in
                self?.profileManager.activateProfile(for: bundleId)
            }
            .store(in: &cancellables)
        
        // Bind Input -> Window Visibility
        inputMonitor.$isOverlayVisible
            .sink { [weak self] isVisible in
                if isVisible {
                    self?.showOverlay()
                } else {
                    self?.hideOverlay()
                }
            }
            .store(in: &cancellables)
    }
    
    
    private func createWindow() {
        let window = OverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            backing: .buffered,
            defer: false
        )
        
        let contentView = RadialMenuView(profileManager: profileManager) { [weak self] macro in
            self?.executeMacro(macro)
        }
        window.contentView = NSHostingView(rootView: contentView)
        self.overlayWindow = window
        // Ensure it starts hidden
        window.orderOut(nil)
    }
    
    func showOverlayManually() {
        showOverlay()
    }
    
    func executeMacro(_ macro: Macro) {
        print("Executing macro: \(macro.label)")
        
        // Hide window first
        hideOverlay()
        
        // Force activate the last known app
        if let lastApp = contextManager.lastActiveApp {
            print("Activating last app: \(lastApp.localizedName ?? "Unknown")")
            lastApp.activate(options: .activateIgnoringOtherApps)
        } else {
            print("No last active app found, relying on system focus")
            NSApp.hide(nil) // Extra measure to yield focus
        }
        
        // Delay to ensure activation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            MacroExecutor.shared.execute(macro)
        }
    }
    
    private func showOverlay() {
        guard let window = overlayWindow else { return }
        
        let mouseLoc = NSEvent.mouseLocation
        // Center window on mouse
        let windowSize = window.frame.size
        let origin = CGPoint(
            x: mouseLoc.x - windowSize.width / 2,
            y: mouseLoc.y - windowSize.height / 2
        )
        
        window.setFrameOrigin(origin)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
    }
}
