import SwiftUI

struct SnippetDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var snippetManager: SnippetManager
    let snippet: Snippet
    
    @State private var name: String
    @State private var language: String
    @State private var code: String
    @State private var showDeleteConfirmation = false
    
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
                            HStack {
                                LanguageIconView(language: lang.1)
                                    .frame(width: 16, height: 16)
                                Text(lang.0)
                            }
                            .tag(lang.1)
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
                    showDeleteConfirmation = true
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
        .alert("Delete Snippet?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                snippetManager.deleteSnippet(snippet)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(snippet.name)'? This action cannot be undone.")
        }
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
