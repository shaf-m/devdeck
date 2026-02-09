import SwiftUI

struct SnippetDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var snippetManager: SnippetManager
    let snippet: Snippet
    
    @State private var name: String
    @State private var language: String
    @State private var code: String
    @State private var notes: String
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
        _notes = State(initialValue: snippet.notes)
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
            
            HStack(alignment: .top, spacing: 20) {
                // Left Column: Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            TextField("Enter snippet name...", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Language")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            LanguagePicker(selection: $language, languages: languages.map { ($0.0, $0.1) })
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            TextEditor(text: $notes)
                                .font(.body)
                                .frame(height: 150)
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
            
            Divider()
            
            HStack {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save Changes") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || code.isEmpty)
                .keyboardShortcut("s", modifiers: .command) // Cmd+S for Save
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .padding(0) // Remove outer padding to let footer stretch
        .frame(width: 900, height: 700)
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
        
        // 3. Update Notes
        if notes != snippet.notes {
            snippetManager.updateNotes(for: snippet, notes: notes)
        }
        
        dismiss()
    }
}
