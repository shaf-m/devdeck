import Foundation
import Combine

struct Snippet: Identifiable, Codable, Hashable {
    var id: String { url.path }
    let url: URL
    var name: String { url.deletingPathExtension().lastPathComponent }
    var content: String
    var language: String { url.pathExtension }
    var isDirectory: Bool
    var isPinned: Bool = false
    var children: [Snippet]? // For directories
}

class SnippetManager: ObservableObject {
    @Published var snippets: [Snippet] = []
    
    private var pinnedSnippetIDs: Set<String> = []
    private let pinnedKey = "devdeck.pinnedSnippets"
    
    // Base Directory: ~/.devdeck/snippets
    private var baseURL: URL? {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".devdeck")
            .appendingPathComponent("snippets")
    }
    
    init() {
        if let savedPins = UserDefaults.standard.array(forKey: pinnedKey) as? [String] {
            pinnedSnippetIDs = Set(savedPins)
        }
        createBaseDirectoryIfNeeded()
        loadSnippets()
    }
    
    private func createBaseDirectoryIfNeeded() {
        guard let url = baseURL else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            // Create some default examples
            createDefaultSnippets()
        }
    }
    
    private func createDefaultSnippets() {
        createSnippet(name: "Hello World", content: "echo 'Hello World'", language: "sh", folder: nil)
        createSnippet(name: "List Files", content: "ls -la", language: "sh", folder: "Utils")
    }
    
    func loadSnippets() {
        guard let url = baseURL else { return }
        self.snippets = scanDirectory(at: url)
    }
    
    private func scanDirectory(at url: URL) -> [Snippet] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        var result: [Snippet] = []
        
        for fileURL in contents {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir)
            
            if isDir.boolValue {
                let children = scanDirectory(at: fileURL)
                result.append(Snippet(url: fileURL, content: "", isDirectory: true, isPinned: false, children: children))
            } else {
                if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                    let isPinned = pinnedSnippetIDs.contains(fileURL.path)
                    result.append(Snippet(url: fileURL, content: content, isDirectory: false, isPinned: isPinned, children: nil))
                }
            }
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    func createSnippet(name: String, content: String, language: String, folder: String?) {
        guard let baseURL = baseURL else { return }
        
        var targetDir = baseURL
        if let folder = folder {
            targetDir = baseURL.appendingPathComponent(folder)
            if !FileManager.default.fileExists(atPath: targetDir.path) {
                try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
            }
        }
        
        let filename = name.hasSuffix("." + language) ? name : "\(name).\(language)"
        let fileURL = targetDir.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            loadSnippets()
        } catch {
            print("Failed to save snippet: \(error)")
        }
    }
    
    func deleteSnippet(_ snippet: Snippet) {
        try? FileManager.default.removeItem(at: snippet.url)
        loadSnippets()
    }
    
    func updateSnippet(_ snippet: Snippet, newContent: String) {
        do {
            try newContent.write(to: snippet.url, atomically: true, encoding: .utf8)
            loadSnippets()
        } catch {
            print("Failed to update snippet: \(error)")
        }
    }
    
    func renameSnippet(_ snippet: Snippet, newName: String, newLanguage: String) {
        let directory = snippet.url.deletingLastPathComponent()
        let filename = newName.hasSuffix("." + newLanguage) ? newName : "\(newName).\(newLanguage)"
        let newURL = directory.appendingPathComponent(filename)
        
        do {
            try FileManager.default.moveItem(at: snippet.url, to: newURL)
            loadSnippets()
        } catch {
            print("Failed to rename snippet: \(error)")
        }
    }
    func togglePin(for snippet: Snippet) {
        if pinnedSnippetIDs.contains(snippet.id) {
            pinnedSnippetIDs.remove(snippet.id)
        } else {
            pinnedSnippetIDs.insert(snippet.id)
        }
        UserDefaults.standard.set(Array(pinnedSnippetIDs), forKey: pinnedKey)
        loadSnippets() // Reload to update UI state
    }
}
