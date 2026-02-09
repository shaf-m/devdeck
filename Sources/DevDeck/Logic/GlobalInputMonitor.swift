import Cocoa
import Combine
import CoreGraphics

class GlobalInputMonitor: ObservableObject {
    @Published var isOverlayVisible: Bool = false
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Key code for Tilde/Backtick on US QWERTY is 50
    private let targetKeyCode: Int64 = 50
    private var keyDownTime: Date?
    private let holdThreshold: TimeInterval = 0.2 // 200ms
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        // PERMISSION CHECK
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("AXIsProcessTrusted: \(isTrusted)")
        
        if !isTrusted {
            print("WARNING: Accessibility permissions NOT granted. Input monitoring will fail.")
        }
    
        // 1. Create the event mask for KeyDown and KeyUp
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        // 2. Create the Tap
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let mySelf = Unmanaged<GlobalInputMonitor>.fromOpaque(refcon).takeUnretainedValue()
            
            if let result = mySelf.handleEvent(proxy: proxy, type: type, event: event) {
                return Unmanaged.passUnretained(result)
            } else {
                return nil
            }
        }
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPointer
        ) else {
            print("Failed to create event tap. Check Accessibility Permissions.")
            return
        }

        self.eventTap = tap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("Input Monitor Started (EventTapManager Logic)")
    }
    
    func stopMonitoring() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        self.eventTap = nil
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> CGEvent? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        guard keyCode == targetKeyCode else {
            return event
        }
        
        // Debug
        // print("Tilde Event: \(type.rawValue)")

        if type == .keyDown {
            // Check if this is a repeat event (holding the key down)
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
                return nil // Swallow repeats
            }
            
            keyDownTime = Date()
            
            // Start a timer to trigger the swatch if they keep holding
            DispatchQueue.main.asyncAfter(deadline: .now() + holdThreshold) { [weak self] in
                guard let self = self else { return }
                if let downTime = self.keyDownTime, Date().timeIntervalSince(downTime) >= self.holdThreshold {
                    // Holding it!
                     DispatchQueue.main.async {
                         if !self.isOverlayVisible {
                             self.isOverlayVisible = true
                             print("Hold Detected -> Overlay Visible")
                         }
                     }
                }
            }
            return nil // Swallow initial down to see if it's a hold
        } 
        
        if type == .keyUp {
            let duration = Date().timeIntervalSince(keyDownTime ?? Date())
            keyDownTime = nil
            
            if duration < holdThreshold {
                // IT WAS A TAP: Manually re-inject the tilde key
                print("Tap Detected (< 0.2s) -> Reinjecting")
                reinjectKey(keyCode: CGKeyCode(targetKeyCode), flags: event.flags)
                return nil 
            } else {
                // IT WAS A HOLD
                print("Hold Released -> Hiding Overlay")
                 DispatchQueue.main.async {
                     if self.isOverlayVisible {
                         self.isOverlayVisible = false
                     }
                 }
                return nil
            }
        }

        return event
    }

    private func reinjectKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
        }
        
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
