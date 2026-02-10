import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct SnippetExportData: Codable {
    let name: String
    let content: String
    let language: String
    let notes: String
    let isPinned: Bool
    let folder: String? // "Utils", or nested path
}

struct BackupData: Codable {
    var version: Int = 1
    var timestamp: Date = Date()
    let profiles: [Profile]
    let snippets: [SnippetExportData]
}

class ImportExportManager: ObservableObject {
    static let shared = ImportExportManager()
    
    // Dependencies
    var profileManager: PersistenceManager = PersistenceManager.shared
    
    // MARK: - UI Interaction
    
    func presentExportPanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.devDeckBackup]
        panel.nameFieldStringValue = "DevDeck_Backup_\(dateString()).json"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try self.exportBackup(to: url)
                    self.showAlert(title: "Export Successful", message: "Backup saved to \(url.lastPathComponent)")
                } catch {
                    self.showAlert(title: "Export Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    func presentImportPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.devDeckBackup]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try self.importBackup(from: url)
                    self.showAlert(title: "Import Successful", message: "Profiles and snippets have been imported.")
                    
                    // Reload App State if possible?
                    // We rely on Managers refreshing themselves or the App reloading.
                    // SnippetManager watches file system? No, it refreshes on manual calls.
                    // We might need to post a notification or have the user restart.
                    NotificationCenter.default.post(name: Notification.Name("RefreshData"), object: nil)
                } catch {
                    self.showAlert(title: "Import Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Core Logic
    
    func createBackup() -> BackupData {
        let profiles = profileManager.loadProfiles()
        let snippets = gatherSnippets()
        return BackupData(profiles: profiles, snippets: snippets)
    }
    
    func exportBackup(to url: URL) throws {
        let backup = createBackup()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(backup)
        try data.write(to: url)
    }
    
    func importBackup(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(BackupData.self, from: data)
        
        importProfiles(backup.profiles)
        importSnippets(backup.snippets)
    }
    
    private func importProfiles(_ newProfiles: [Profile]) {
        var currentProfiles = profileManager.loadProfiles()
        
        for var profile in newProfiles {
            // Check if exact duplicate exists (same name and macros)
            // If so, maybe skip? But requirement says "only add them".
            // To be safe and "add", we generate new ID to ensure it's a distinct entry.
            profile.id = UUID()
            
            // If name exists, append " (Imported)" to avoid confusion?
            if currentProfiles.contains(where: { $0.name == profile.name }) {
                profile.name = "\(profile.name) (Imported)"
            }
            
            currentProfiles.append(profile)
        }
        
        profileManager.saveProfiles(currentProfiles)
    }
    
    private func importSnippets(_ newSnippets: [SnippetExportData]) {
        let fileManager = FileManager.default
        guard let baseURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".devdeck")
            .appendingPathComponent("snippets") as URL? else { return }
            
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        
        // Load existing state for merging
        var pinnedIDs = Set(UserDefaults.standard.array(forKey: "devdeck.pinnedSnippets") as? [String] ?? [])
        var snippetNotes = UserDefaults.standard.dictionary(forKey: "devdeck.snippetNotes") as? [String: String] ?? [:]
        
        for snippet in newSnippets {
            var targetDir = baseURL
            // Reconstruct folder structure if present
            if let folder = snippet.folder, !folder.isEmpty {
                // Sanitize folder path (prevent .. or absolute paths)
                let safeComponents = folder.split(separator: "/").map(String.init).filter { $0 != ".." && !$0.hasPrefix("/") }
                for component in safeComponents {
                    targetDir = targetDir.appendingPathComponent(component)
                }
                try? fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
            }
            
            let safeName = snippet.name.replacingOccurrences(of: "/", with: "-")
            let filename = safeName.hasSuffix("." + snippet.language) ? safeName : "\(safeName).\(snippet.language)"
            var fileURL = targetDir.appendingPathComponent(filename)
            
            // Collision handling: Rename if exists
            var counter = 1
            while fileManager.fileExists(atPath: fileURL.path) {
                let nameWithoutExt = (filename as NSString).deletingPathExtension // This might be naive if name has multiple dots, but ok for now
                let ext = (filename as NSString).pathExtension
                // Remove existing counter if present to avoid (1) (1)
                // For simplicity, just append counter
                // Check if nameWithoutExt already ends with " (N)"
                let newBaseName = "\(safeName) (\(counter))"
                let newFilename = ext.isEmpty ? newBaseName : "\(newBaseName).\(ext)"
                fileURL = targetDir.appendingPathComponent(newFilename)
                counter += 1
            }
            
            do {
                try snippet.content.write(to: fileURL, atomically: true, encoding: .utf8)
                
                // Restore Metadata (Pins & Notes)
                if snippet.isPinned {
                    pinnedIDs.insert(fileURL.path)
                }
                if !snippet.notes.isEmpty {
                    snippetNotes[fileURL.path] = snippet.notes
                }
                
            } catch {
                print("Failed to save imported snippet: \(error)")
            }
        }
        
        // Save updated metadata
        UserDefaults.standard.set(Array(pinnedIDs), forKey: "devdeck.pinnedSnippets")
        UserDefaults.standard.set(snippetNotes, forKey: "devdeck.snippetNotes")
    }
    
    // Helper to gather snippets recursively
    private func gatherSnippets() -> [SnippetExportData] {
        let fileManager = FileManager.default
        let baseURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".devdeck")
            .appendingPathComponent("snippets")
            
        guard fileManager.fileExists(atPath: baseURL.path) else { return [] }
        
        var collected: [SnippetExportData] = []
        
        // Helper to retrieve notes/pins
        let snippetNotes = UserDefaults.standard.dictionary(forKey: "devdeck.snippetNotes") as? [String: String] ?? [:]
        let pinnedIDs = Set(UserDefaults.standard.array(forKey: "devdeck.pinnedSnippets") as? [String] ?? [])
        
        // Recursive scan
        func scan(directory: URL, relativePath: String?) {
            guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return }
            
            for url in contents {
                var isDir: ObjCBool = false
                fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
                
                if isDir.boolValue {
                    let folderName = url.lastPathComponent
                    let newRelativePath = relativePath == nil ? folderName : "\(relativePath!)/\(folderName)"
                    scan(directory: url, relativePath: newRelativePath)
                } else {
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        let name = url.deletingPathExtension().lastPathComponent
                        let language = url.pathExtension
                        let notes = snippetNotes[url.path] ?? ""
                        let isPinned = pinnedIDs.contains(url.path)
                        
                        collected.append(SnippetExportData(
                            name: name,
                            content: content,
                            language: language,
                            notes: notes,
                            isPinned: isPinned,
                            folder: relativePath
                        ))
                    }
                }
            }
        }
        
        scan(directory: baseURL, relativePath: nil)
        return collected
    }
}

extension UTType {
    static var devDeckBackup: UTType {
        UTType(exportedAs: "com.shafm.devdeck.backup", conformingTo: .json)
    }
}
