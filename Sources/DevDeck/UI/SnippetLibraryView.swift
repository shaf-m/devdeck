import SwiftUI

struct SnippetLibraryView: View {
    @StateObject var snippetManager = SnippetManager()
    @State private var sortedSnippets: [Snippet] = []
    @State private var searchText = ""
    @State private var selectedSnippet: Snippet?
    @State private var showNewSnippetAlert = false
    @State private var newSnippetName = ""
    @State private var editingSnippet: Snippet?
    
    // Filters
    @State private var selectedLanguage: String = "All"
    @State private var sortAscending: Bool = true
    
    let languages = ["All", "sh", "py", "applescript", "txt", "json"]
    
    var filteredSnippets: [Snippet] {
        // If no filter, return all (sorted)
        if searchText.isEmpty && selectedLanguage == "All" {
            return sortSnippets(snippetManager.snippets)
        }
        return filterAndSort(snippets: snippetManager.snippets)
    }
    
    func sortSnippets(_ snippets: [Snippet]) -> [Snippet] {
        let sorted = snippets.sorted {
            sortAscending ? $0.name.localizedStandardCompare($1.name) == .orderedAscending :
                           $0.name.localizedStandardCompare($1.name) == .orderedDescending
        }
        // Recursively sort children
        return sorted.map { snippet in
            var newSnippet = snippet
            if let children = snippet.children {
                newSnippet.children = sortSnippets(children)
            }
            return newSnippet
        }
    }
    
    func filterAndSort(snippets: [Snippet]) -> [Snippet] {
        var result: [Snippet] = []
        
        for snippet in snippets {
            // Check if matches criteria
            let matchesLang = selectedLanguage == "All" || snippet.language == selectedLanguage
            let matchesText = searchText.isEmpty || snippet.name.localizedCaseInsensitiveContains(searchText)
            
            // Allow if matches OR if children match
            var childrenMatch: [Snippet]? = nil
            if let children = snippet.children {
                childrenMatch = filterAndSort(snippets: children)
            }
            
            if (matchesLang && matchesText) || (childrenMatch != nil && !childrenMatch!.isEmpty) {
                var newSnippet = snippet
                if let childrenMatch = childrenMatch {
                    newSnippet.children = childrenMatch
                }
                result.append(newSnippet)
            }
        }
        
        return sortSnippets(result)
    }
    
    func languageDisplayName(_ code: String) -> String {
        switch code {
        case "All": return "All Languages"
        case "sh": return "Shell Script"
        case "py": return "Python"
        case "applescript": return "AppleScript"
        case "txt": return "Plain Text"
        case "json": return "JSON"
        default: return code
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Search
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search Snippets...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                HStack {
                    // Language Filter
                    Picker("Lang", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(languageDisplayName(lang)).tag(lang)
                        }
                    }
                    .frame(width: 140)
                    .labelsHidden()
                    
                    Spacer()
                    
                    // Sort Toggle
                    Button(action: { sortAscending.toggle() }) {
                        HStack(spacing: 4) {
                            Text(sortAscending ? "A-Z" : "Z-A")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: sortAscending ? "arrow.up.circle" : "arrow.down.circle")
                        }
                    }
                    .buttonStyle(.plain)
                    .help(sortAscending ? "Sort Z-A" : "Sort A-Z")
                }
            }
            .padding()
            
            Divider()
            
            // List / Tree
            List(filteredSnippets, children: \.children) { snippet in
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
