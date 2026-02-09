import SwiftUI

struct SnippetLibraryView: View {
    @StateObject var snippetManager = SnippetManager()
    @State private var sortedSnippets: [Snippet] = []
    @State private var searchText = ""
    @State private var selectedSnippet: Snippet?
    @State private var showNewSnippetAlert = false
    @State private var newSnippetName = ""
    @State private var editingSnippet: Snippet?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search Snippets...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // List / Tree
            List(snippetManager.snippets, children: \.children) { snippet in
                SnippetRow(snippet: snippet) {
                    if !snippet.isDirectory {
                        editingSnippet = snippet
                    }
                }
            }
            .listStyle(SidebarListStyle())
            
            Divider()
            
            // Footer (Add Button)
            HStack {
                Button(action: {
                    showNewSnippetAlert = true
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(BorderedButtonStyle())
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 200)
        .sheet(isPresented: $showNewSnippetAlert) {
            SnippetCreationView(snippetManager: snippetManager)
        }
        .sheet(item: $editingSnippet) { snippet in
            SnippetDetailView(snippetManager: snippetManager, snippet: snippet)
        }
    }
}

struct SnippetRow: View {
    let snippet: Snippet
    var onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: snippet.isDirectory ? "folder" : "doc.text")
            Text(snippet.name)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onDrag {
            let data: [String: String] = [
                "name": snippet.name,
                "content": snippet.content,
                "type": "snippet"
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: data),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                 return NSItemProvider(object: jsonString as NSString)
            }
            return NSItemProvider(object: (snippet.content) as NSString)
        }
    }
}
