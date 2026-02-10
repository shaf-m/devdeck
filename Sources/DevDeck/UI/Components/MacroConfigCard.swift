import SwiftUI

struct MacroConfigCard: View {
    @Binding var macro: Macro
    
    var onDelete: () -> Void
    var onEdit: (() -> Void)? = nil
    var isNew: Bool = false
    var onInteract: (() -> Void)? = nil
    
    // SF Symbols for Icon Picker (Simplified list for now)
    let availableIcons = ["terminal", "safari", "folder", "play.fill", "stop.fill", "gear", "command", "globe", "cpu", "keyboard", "text.alignleft"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Icon & Label
            HStack(spacing: 12) { // Added spacing
                // Drag Handle (Leading position for better UX)
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 20))
                    .onTapGesture { onInteract?() }
                    .onChange(of: macro) { _ in
                        onEdit?()
                    }
                    .frame(width: 24)
                    .accessibilityLabel("Drag to Reorder")
                
                Menu {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: { macro.iconName = icon }) {
                            Label(icon, systemImage: icon)
                        }
                    }
                } label: {
                    Image(systemName: macro.iconName ?? "questionmark.circle")
                        .font(.title3) // Slightly smaller
                        .frame(width: 28, height: 28)
                        .padding(6)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 40, height: 40) // Click area
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Label")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Macro Name", text: $macro.label)
                        .textFieldStyle(.plain)
                        .font(.headline)
                }
                
                if isDefaultMacro {
                    Text("NEW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .help("This is a new macro with default values")
                }
                
                Spacer()
                
                // Delete Button
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.6))
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())
                .help("Delete Macro")
            }
            .padding(.bottom, 4)
            
            Divider()
                .background(Color.secondary.opacity(0.2))
            
            // Action Type & Value
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Action Type")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("Action", selection: $macro.type) {
                        Text("Shell Script").tag(MacroType.shellScript)
                        Text("AppleScript").tag(MacroType.appleScript)
                        Text("Key Shortcut").tag(MacroType.keystroke)
                        Text("URL").tag(MacroType.url)
                        Text("Text/Paste").tag(MacroType.text)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: 120)
                }
                
                // Value Editor
                Group {
                    if macro.type == .shellScript || macro.type == .appleScript {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Script")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $macro.value)
                                .font(.system(.caption, design: .monospaced))
                                .frame(height: 70)
                                .scrollContentBackground(.hidden) // Important for custom background
                                .padding(4)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                    } else if macro.type == .keystroke {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shortcut")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ShortcutRecorder(shortcutValue: $macro.value)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField(placeholderForType(macro.type), text: $macro.value)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(height: 240)
        .background(Color(NSColor.controlBackgroundColor)) // Distinct card background
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                
                if isNew || isDefaultMacro {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                }
            }
        )
    }
    
    private func placeholderForType(_ type: MacroType) -> String {
        switch type {
        case .shellScript, .appleScript: return "Script..."
        case .keystroke: return "e.g. ⌘C"
        case .url: return "https://example.com"
        case .text: return "Text to paste..."
        }
    }
    
    private var isDefaultMacro: Bool {
        return macro.label == "New Macro" && 
               macro.value == "echo 'Hello World'" && 
               macro.type == .shellScript
    }
}
