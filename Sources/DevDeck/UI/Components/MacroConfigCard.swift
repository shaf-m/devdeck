import SwiftUI

struct MacroConfigCard: View {
    @Binding var macro: Macro
    
    // SF Symbols for Icon Picker (Simplified list for now)
    let availableIcons = ["terminal", "safari", "folder", "play.fill", "stop.fill", "gear", "command", "globe", "cpu", "keyboard", "text.alignleft"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Icon & Label
            HStack {
                Menu {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: { macro.iconName = icon }) {
                            Label(icon, systemImage: icon)
                        }
                    }
                } label: {
                    Image(systemName: macro.iconName ?? "questionmark.circle")
                        .font(.title2)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .frame(width: 32)
                
                TextField("Label", text: $macro.label)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.headline)
                
                Spacer()
                
                // Drag Handle
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 20))
                    .padding(.leading, 8)
                    .accessibilityLabel("Drag to Reorder")
            }
            
            Divider()
            
            // Action Type
            Picker("Action", selection: $macro.type) {
                Text("Shell Script").tag(MacroType.shellScript)
                Text("AppleScript").tag(MacroType.appleScript)
                Text("Key Shortcut").tag(MacroType.keystroke)
                Text("URL").tag(MacroType.url)
                Text("Text/Paste").tag(MacroType.text)
            }
            .pickerStyle(MenuPickerStyle())
            .labelsHidden()
            
            // Value Editor
            Group {
                if macro.type == .shellScript || macro.type == .appleScript {
                    TextEditor(text: $macro.value)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                } else {
                    TextField("Value (e.g. https://... or ⌘C)", text: $macro.value)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Spacer(minLength: 0) // Push content up, ensure card fills height
        }
        .padding()
        .frame(height: 220) // Fixed height for consistency
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
