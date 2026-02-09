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
    
    let languages = ["All", "sh", "py", "js", "ts", "java", "c", "sql", "html", "css", "json", "yaml", "applescript", "txt"]
    
    var filteredSnippets: [Snippet] {
        // If no filter, return all (sorted)
        if searchText.isEmpty && selectedLanguage == "All" {
            return sortSnippets(snippetManager.snippets)
        }
        return filterAndSort(snippets: snippetManager.snippets)
    }
    
    func sortSnippets(_ snippets: [Snippet]) -> [Snippet] {
        let sorted = snippets.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return sortAscending ? $0.name.localizedStandardCompare($1.name) == .orderedAscending :
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
        case "js": return "JavaScript"
        case "ts": return "TypeScript"
        case "java": return "Java"
        case "c": return "C"
        case "sql": return "SQL"
        case "html": return "HTML"
        case "css": return "CSS"
        case "json": return "JSON"
        case "yaml": return "YAML"
        case "applescript": return "AppleScript"
        case "txt": return "Plain Text"
        default: return code
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Header Area
            VStack(alignment: .leading, spacing: 16) {
                Text("Snippet Manager")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                
                // Search & Filter Container
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search Snippets...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.body)
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                    
                    HStack {
                        // Language Filter
                        Menu {
                            Picker("Language", selection: $selectedLanguage) {
                                ForEach(languages, id: \.self) { lang in
                                    Text(languageDisplayName(lang)).tag(lang)
                                }
                            }
                        } label: {
                            Label(languageDisplayName(selectedLanguage), systemImage: "line.3.horizontal.decrease.circle")
                                .font(.subheadline)
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 160, alignment: .leading)
                        
                        Spacer()
                        
                        // Sort Toggle
                        Button(action: { sortAscending.toggle() }) {
                            HStack(spacing: 4) {
                                Text(sortAscending ? "A-Z" : "Z-A")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Image(systemName: sortAscending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                        }
                        .buttonStyle(.plain)
                        .help(sortAscending ? "Sort Z-A" : "Sort A-Z")
                    }
                }
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // List / Tree
            List(filteredSnippets, children: \.children) { snippet in
                SnippetRow(snippet: snippet, snippetManager: snippetManager) {
                    if !snippet.isDirectory {
                        editingSnippet = snippet
                    }
                }
            }
            .listStyle(SidebarListStyle())
            
            Divider()
            
            // Footer (Add Button)
            HStack {
                Spacer()
                Button(action: {
                    showNewSnippetAlert = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Snippet")
                    }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
            }
        }
        .frame(minWidth: 250)
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
    @ObservedObject var snippetManager: SnippetManager
    var onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if snippet.isDirectory {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                    .font(.body)
            } else {
                LanguageIconView(language: snippet.language)
                    .frame(width: 18, height: 18)
            }
            
            Text(snippet.name)
                .font(.system(.body, design: .rounded))
            
            if snippet.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(45))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button {
                snippetManager.togglePin(for: snippet)
            } label: {
                Label(snippet.isPinned ? "Unpin Snippet" : "Pin Snippet", systemImage: snippet.isPinned ? "pin.slash" : "pin")
            }
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
