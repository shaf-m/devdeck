import SwiftUI
import Carbon

struct ShortcutRecorder: View {
    @Binding var shortcutValue: String
    @State private var isRecording = false
    @State private var eventMonitor: Any?
    
    var body: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            HStack {
                if isRecording {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                        .symbolEffect(.pulse, options: .repeating)
                    Text("Press keys...")
                        .foregroundColor(.red)
                } else {
                    if shortcutValue.isEmpty {
                        Image(systemName: "keyboard")
                        Text("Record Shortcut")
                    } else {
                        Image(systemName: "command")
                        Text(formatDisplayString(shortcutValue))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.red : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onDisappear {
            stopRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        
        // Monitor key down events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyPress(event)
            return nil // Consume event so it doesn't propagate
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        // Build string representation
        var parts: [String] = []
        
        // Modifiers
        if event.modifierFlags.contains(.command) { parts.append("command") }
        if event.modifierFlags.contains(.shift) { parts.append("shift") }
        if event.modifierFlags.contains(.control) { parts.append("control") }
        if event.modifierFlags.contains(.option) { parts.append("option") }
        
        // Key Code
        // Ignore standalone modifiers
        // 54=Command(Right), 55=Command(Left), 56=Shift(Left), 57=Capslock, 58=Option(Left), 59=Control(Left), 60=Shift(Right), 61=Option(Right), 62=Control(Right), 63=Fn
        let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
        
        if !modifierKeyCodes.contains(event.keyCode) {
            if let keyString = KeyCodeMap.string(for: CGKeyCode(event.keyCode)) {
                parts.append(keyString)
            } else {
                 print("Unknown key code: \(event.keyCode)")
            }
        }
        
        if !parts.isEmpty {
            let newShortcut = parts.joined(separator: "+")
            
            // Check for Escape to cancel?
            if event.keyCode == 53 && parts.count == 1 { // Only Escape
                // Cancel
                stopRecording()
                return
            }
            
            self.shortcutValue = newShortcut
            stopRecording()
        }
    }
    
    private func formatDisplayString(_ raw: String) -> String {
        return raw.split(separator: "+")
            .map { part in
                switch part {
                case "command": return "⌘"
                case "shift": return "⇧"
                case "option": return "⌥"
                case "control": return "⌃"
                default: return String(part).capitalized
                }
            }
            .joined(separator: "")
    }
}
