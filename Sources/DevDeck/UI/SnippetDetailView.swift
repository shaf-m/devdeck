import SwiftUI

struct SnippetDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var snippetManager: SnippetManager
    let snippet: Snippet
    
    @State private var name: String
    @State private var language: String
    @State private var code: String
    
    let languages = [
        ("Shell Script", "sh"),
        ("Python", "py"),
        ("AppleScript", "applescript"),
        ("Plain Text", "txt"),
        ("JSON", "json")
    ]
    
    init(snippetManager: SnippetManager, snippet: Snippet) {
        self.snippetManager = snippetManager
        self.snippet = snippet
        // Initialize state with snippet data
        _name = State(initialValue: snippet.name)
        _language = State(initialValue: snippet.language)
        _code = State(initialValue: snippet.content)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Edit Snippet")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Form {
                TextField("Name", text: $name)
                
                Picker("Language", selection: $language) {
                    ForEach(languages, id: \.1) { lang in
                        Text(lang.0).tag(lang.1)
                    }
                }
                
                Section(header: Text("Code")) {
                    TextEditor(text: $code)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 300)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button(role: .destructive) {
                    snippetManager.deleteSnippet(snippet)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                Spacer()
                
                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(code, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Button("Save Changes") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 600, height: 600)
    }
    
    private func saveChanges() {
        // 1. Update Content
        if code != snippet.content {
            snippetManager.updateSnippet(snippet, newContent: code)
        }
        
        // 2. Rename / Change Language if needed
        // Note: Renaming relies on the 'current' file URL. If we just updated content, the file is still there.
        // If we rename, the file moves.
        // Ideally we do rename LAST so the URL is valid for update. 
        // Or update first, then rename.
        
        if name != snippet.name || language != snippet.language {
            // We need to re-fetch the fresh snippet reference potentially if updateSnippet didn't refresh 'snippet' locally (it doesn't, 'snippet' is a let struct).
            // But 'snippet' struct holds the URL. updateSnippet writes to that URL. 
            // So the URL is still valid.
            snippetManager.renameSnippet(snippet, newName: name, newLanguage: language)
        }
        
        dismiss()
    }
}
