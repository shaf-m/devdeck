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
                .font(.title2)
                .bold()
                .padding(.top, 10)
            
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
                    .frame(minHeight: 250)
                }
            }
            .formStyle(.grouped)
            
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
        .frame(width: 550, height: 600)
    }
    
    private func saveSnippet() {
        snippetManager.createSnippet(name: name, content: code, language: language, folder: nil)
        dismiss()
    }
}
