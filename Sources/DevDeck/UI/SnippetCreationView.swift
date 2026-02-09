import SwiftUI

struct SnippetCreationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var snippetManager: SnippetManager
    
    @State private var name: String = ""
    @State private var language: String = "sh"
    @State private var code: String = ""
    
    let languages = [
        ("Shell Script", "sh"),
        ("Python", "py"),
        ("AppleScript", "applescript"),
        ("Plain Text", "txt"),
        ("JSON", "json")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Snippet")
                .font(.headline)
            
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
                        .frame(minHeight: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                
                Button("Save Snippet") {
                    saveSnippet()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || code.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 500)
    }
    
    private func saveSnippet() {
        snippetManager.createSnippet(name: name, content: code, language: language, folder: nil)
        dismiss()
    }
}
