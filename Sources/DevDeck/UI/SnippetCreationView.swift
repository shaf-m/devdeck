import SwiftUI

struct SnippetCreationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var snippetManager: SnippetManager
    
    @State private var name: String = ""
    @State private var language: String = "sh"
    @State private var code: String = ""
    @State private var notes: String = ""
    
    let languages = [
        ("Shell Script", "sh"),
        ("Python", "py"),
        ("JavaScript", "js"),
        ("TypeScript", "ts"),
        ("Java", "java"),
        ("C", "c"),
        ("SQL", "sql"),
        ("HTML", "html"),
        ("CSS", "css"),
        ("JSON", "json"),
        ("YAML", "yaml"),
        ("AppleScript", "applescript"),
        ("Plain Text", "txt")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Snippet")
                .font(.title2)
                .bold()
                .padding(.top, 10)
            
            HStack(alignment: .top, spacing: 20) {
                // Left Column: Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Language")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            LanguagePicker(selection: $language, languages: languages.map { ($0.0, $0.1) })
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $notes)
                                .font(.body)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                }
                .frame(width: 250)
                
                // Right Column: Code
                VStack(alignment: .leading, spacing: 8) {
                    Text("Code")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    CodeEditorView(
                        text: $code,
                        language: language
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding()
            
            HStack(spacing: 16) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save Snippet") {
                    saveSnippet()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || code.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 16)
        }
        .padding()
        .frame(width: 800, height: 600)
    }
    
    private func saveSnippet() {
        snippetManager.createSnippet(name: name, content: code, language: language, folder: nil, notes: notes)
        dismiss()
    }
}
