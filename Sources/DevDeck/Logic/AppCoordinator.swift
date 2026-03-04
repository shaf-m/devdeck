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
    private var hostingController: NSHostingController<RadialMenuView>?
    /// Cursor location captured at the moment the overlay is shown — used for horizontal centering.
    private var lastCursorLocation: NSPoint = .zero
    
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
            },
            onResize: { [weak self] in
                // Fired when menuMode or profile changes — resize window to new content height
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.resizeToContent()
                }
            }
        )
        let controller = NSHostingController(rootView: contentView)
        controller.view.wantsLayer = true
        controller.view.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentViewController = controller
        self.hostingController = controller
        self.overlayWindow = window
        window.orderOut(nil)
    }

    // MARK: - Window Sizing

    /// Reads the SwiftUI fittingSize and snaps the window to it, then repositions flush at the menu bar.
    private func resizeToContent() {
        guard let window = overlayWindow, let controller = hostingController else { return }
        let fitting = controller.view.fittingSize
        guard fitting.height > 10 else { return }   // guard against zero during early layout
        window.setContentSize(fitting)
        repositionAtMenuBar()
    }

    private func repositionAtMenuBar() {
        guard let window = overlayWindow else { return }
        let windowSize = window.frame.size
        let cursor = lastCursorLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(cursor, $0.frame, false) }) ?? NSScreen.main
        if let screen {
            let vf = screen.visibleFrame
            // Top edge flush with the bottom of the menu bar
            let y = vf.maxY - windowSize.height
            // Horizontally centred on the cursor, clamped within the screen
            let x = min(max(cursor.x - windowSize.width / 2, vf.minX), vf.maxX - windowSize.width)
            window.setFrameOrigin(CGPoint(x: x, y: y))
        }
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

        lastCursorLocation = NSEvent.mouseLocation

        // Place offscreen so SwiftUI can lay out before we read fittingSize.
        window.setFrameOrigin(NSPoint(x: -9999, y: 0))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // After one run-loop the view has been laid out and fittingSize is accurate.
        DispatchQueue.main.async { [weak self] in
            self?.resizeToContent()
            // Dismiss when clicking outside the panel
            self?.globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] _ in
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
