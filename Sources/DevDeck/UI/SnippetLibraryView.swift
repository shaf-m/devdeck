import SwiftUI

struct SnippetLibraryView: View {
    @StateObject var snippetManager = SnippetManager()
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
            let matchesLang = selectedLanguage == "All" || snippet.language == selectedLanguage
            let matchesText = searchText.isEmpty || snippet.name.localizedCaseInsensitiveContains(searchText)
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
        case "All": return "All"
        case "sh": return "Shell"
        case "py": return "Python"
        case "js": return "JS"
        case "ts": return "TS"
        case "java": return "Java"
        case "c": return "C"
        case "sql": return "SQL"
        case "html": return "HTML"
        case "css": return "CSS"
        case "json": return "JSON"
        case "yaml": return "YAML"
        case "applescript": return "Script"
        case "txt": return "Text"
        default: return code
        }
    }

    var totalSnippetCount: Int {
        func count(_ snippets: [Snippet]) -> Int {
            snippets.reduce(0) { acc, s in
                acc + (s.isDirectory ? count(s.children ?? []) : 1)
            }
        }
        return count(snippetManager.snippets)
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Snippets")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 4)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search snippets...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(9)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                )

                // Language Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(languages, id: \.self) { lang in
                            LanguageChip(
                                label: languageDisplayName(lang),
                                isSelected: selectedLanguage == lang
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedLanguage = lang
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // ── List ──────────────────────────────────────────────────────
            if filteredSnippets.isEmpty {
                SnippetEmptyState(
                    isFiltered: !searchText.isEmpty || selectedLanguage != "All",
                    onClear: {
                        searchText = ""
                        selectedLanguage = "All"
                    },
                    onAdd: { showNewSnippetAlert = true }
                )
            } else {
                List(filteredSnippets, children: \.children) { snippet in
                    SnippetRow(snippet: snippet, snippetManager: snippetManager) {
                        if !snippet.isDirectory {
                            editingSnippet = snippet
                        }
                    }
                }
                .listStyle(SidebarListStyle())
            }

            Divider()

            // ── Footer ────────────────────────────────────────────────────
            Button(action: { showNewSnippetAlert = true }) {
                HStack {
                    Image(systemName: "curlybraces")
                    Text("Add Snippet")
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("n", modifiers: .command)
            .padding(.horizontal)
            .padding(.bottom, 16)
            .padding(.top, 8)
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

// MARK: - Language Filter Chip

struct LanguageChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isSelected
                        ? AnyView(LinearGradient(colors: [.blue, .purple],
                                startPoint: .leading, endPoint: .trailing))
                        : AnyView(Color(NSColor.controlBackgroundColor))
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color.secondary.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct SnippetEmptyState: View {
    let isFiltered: Bool
    let onClear: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle" : "curlybraces.square")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.35))

            Text(isFiltered ? "No Matching Snippets" : "No Snippets Yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(isFiltered
                 ? "Try adjusting your search or language filter."
                 : "Save frequently used code blocks and insert them anywhere.")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            if isFiltered {
                Button("Clear Filters", action: onClear)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else {
                Button(action: onAdd) {
                    Label("Create First Snippet", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
}

// MARK: - Snippet Row

struct SnippetRow: View {
    let snippet: Snippet
    @ObservedObject var snippetManager: SnippetManager
    var onTap: () -> Void

    /// First non-empty content line, trimmed
    private var contentPreview: String? {
        guard !snippet.isDirectory, !snippet.content.isEmpty else { return nil }
        let firstLine = snippet.content
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }

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

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(snippet.name)
                        .font(.system(.body, design: .rounded))
                    if snippet.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .rotationEffect(.degrees(45))
                    }
                }
                if let preview = contentPreview {
                    Text(preview)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()

            if !snippet.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .contextMenu {
            Button {
                snippetManager.togglePin(for: snippet)
            } label: {
                Label(
                    snippet.isPinned ? "Unpin Snippet" : "Pin Snippet",
                    systemImage: snippet.isPinned ? "pin.slash" : "pin"
                )
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
