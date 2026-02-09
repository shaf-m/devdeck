import SwiftUI

struct SnippetEditorView: View {
    @Binding var text: String
    var language: String
    
    // Simple TextEditor for now, could be enhanced with HIGHLIGHTING later
    // TextKit integration requires NSViewControllerRepresentable for NSTextView
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language.uppercased())
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .background(Color(NSColor.textBackgroundColor))
        }
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}
