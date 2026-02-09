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
                    .font(.title2)
                    .bold()
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding([.top, .horizontal])
            
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Language", selection: $language) {
                        ForEach(languages, id: \.1) { lang in
                            Text(lang.0).tag(lang.1)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Code")) {
                    CodeEditorView(
                        text: $code,
                        language: language
                    )
                    .frame(minHeight: 350)
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
                
                Button("Save Changes") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || code.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom])
        }
        .padding()
        .frame(width: 650, height: 700)
    }
    
    private func saveChanges() {
        // 1. Update Content
        if code != snippet.content {
            snippetManager.updateSnippet(snippet, newContent: code)
        }
        
        // 2. Rename / Change Language
        if name != snippet.name || language != snippet.language {
            snippetManager.renameSnippet(snippet, newName: name, newLanguage: language)
        }
        
        dismiss()
    }
}
