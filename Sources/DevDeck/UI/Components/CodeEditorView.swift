import SwiftUI
import AppKit

struct CodeEditorView: View {
    @Binding var text: String
    var language: String
    var isEditable: Bool = true
    
    @State private var lineCount: Int = 1
    
    var body: some View {
        HStack(spacing: 0) {
            // Line Numbers Gutter
            VStack(spacing: 0) {
                // Calculate line numbers based on text
                // This is a simple approximation. For a real code editor, 
                // we'd need to sync scrolling with the text view which is complex in pure SwiftUI.
                // For now, we'll just show line numbers relative to the lines in the string.
                // Note: unique line height in TextEditor is tricky.
                // Let's use a simple ZStack approach or just a clean editor without line numbers if it's too janky.
                //
                // Actually, let's keep it clean for now: just the editor, but styled nicely.
                // A full line-number sync is hard without NSTextView wrapping.
            }
            //.width(30)
            
            ZStack(alignment: .topTrailing) {
                if isEditable {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .lineSpacing(4)
                        .scrollContentBackground(.hidden) // Allow custom background
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                } else {
                    ScrollView {
                        Text(text)
                            .font(.system(.body, design: .monospaced))
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .textSelection(.enabled)
                    }
                    .background(Color(NSColor.textBackgroundColor))
                }
                
                // Overlay Button
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(text, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .padding(8)
                .help("Copy to Clipboard")
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
