import Cocoa
import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var profileManager = ProfileManager()
    @Published var clipboardManager = ClipboardHistoryManager()
    
    private var inputMonitor = GlobalInputMonitor()
    private var contextManager = ContextManager()
    
    private var overlayWindow: OverlayWindow?
    private var cancellables = Set<AnyCancellable>()
    
    private var shortcutMonitor: Any?
    private var menuBarManager: MenuBarManager?
    private var globalClickMonitor: Any?
    
    init() {
        // AppCoordinator is a root class conforming to ObservableObject, no super.init needed.
        
        setupBindings()
        createWindow()
        setupShortcutMonitor()
        
        // Initialize MenuBarManager after a slight delay or dispatch main to ensure App is ready?
        // Actually safe to do here.
        self.menuBarManager = MenuBarManager(coordinator: self)
    }
       
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
            contentRect: NSRect(x: 0, y: 0, width: 370, height: 600),
            backing: .buffered,
            defer: false
        )
        
        let contentView = RadialMenuView(
            profileManager: profileManager,
            clipboardManager: clipboardManager,
            onExecute: { [weak self] macro in
                self?.executeMacro(macro)
            },
            onPaste: { [weak self] item in
                // Copy to clipboard only — the view handles the toast and keeps the panel open
                self?.clipboardManager.copy(item)
            },
            onClose: { [weak self] in
                self?.hideOverlay()
            },
            onOpenDashboard: {
                if let url = URL(string: "devdeck://dashboard") {
                    NSWorkspace.shared.open(url)
                }
            }
        )
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.sizingOptions = [.preferredContentSize]
        window.contentView = hostingView
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
            lastApp.activate()
        } else {
            print("No last active app found, relying on system focus")
            NSApp.hide(nil) // Extra measure to yield focus
        }
        
        // Delay to ensure activation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            MacroExecutor.shared.execute(macro)
        }
    }
    
    func handlePaste(_ item: ClipboardItem) {
        // 1. Put on clipboard (ensure it's the active item)
        clipboardManager.copy(item)
        
        // 2. Hide window
        hideOverlay()
        
        // 3. Activate last app and paste
        if let lastApp = contextManager.lastActiveApp {
             lastApp.activate()
        } else {
             NSApp.hide(nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        let kVK_ANSI_V: CGKeyCode = 0x09
        let cmdKey: CGEventFlags = .maskCommand
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_ANSI_V, keyDown: true)
        keyDown?.flags = cmdKey
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_ANSI_V, keyDown: false)
        keyUp?.flags = cmdKey
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func showOverlay() {
        guard let window = overlayWindow else { return }

        let mouseLoc = NSEvent.mouseLocation

        // Show offscreen first — this lets sizingOptions apply SwiftUI's real
        // content height before we read window.frame.size for positioning.
        window.setFrameOrigin(NSPoint(x: -9999, y: 0))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // One run-loop later the window has been resized to its actual content.
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.overlayWindow else { return }

            let windowSize = window.frame.size
            let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
                ?? NSScreen.main

            var origin = CGPoint(x: 0, y: 0)
            if let screen {
                let visibleFrame = screen.visibleFrame
                // Anchor just below the menu bar (top of visible area)
                let y = visibleFrame.maxY - windowSize.height
                // Center horizontally on the cursor, clamped to screen edges
                let x = min(
                    max(mouseLoc.x - windowSize.width / 2, visibleFrame.minX),
                    visibleFrame.maxX - windowSize.width
                )
                origin = CGPoint(x: x, y: y)
            }

            window.setFrameOrigin(origin)

            // Dismiss when clicking outside the panel
            self.globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.hideOverlay()
            }
        }

    }
    
    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }
}
