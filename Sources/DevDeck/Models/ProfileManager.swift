import Foundation
import Combine

class ProfileManager: ObservableObject {
    @Published var activeProfile: Profile?
    @Published var profiles: [Profile] = []
    
    init() {
        loadProfiles()
    }
    
    private func loadProfiles() {
        self.profiles = PersistenceManager.shared.loadProfiles()
        
        // ensure there is at least a Global profile
        if self.profiles.isEmpty {
            // Restore full defaults
            let global = Profile(name: "Global", macros: [
                Macro(label: "Safari", type: .shellScript, value: "open -a Safari", iconName: "safari"),
                Macro(label: "Note", type: .text, value: "Meeting Notes:\n- ", iconName: "note.text", pressEnter: false),
                Macro(label: "Space Left", type: .keystroke, value: "ctrl+left", iconName: "arrow.left.circle"),
                Macro(label: "Space Right", type: .keystroke, value: "ctrl+right", iconName: "arrow.right.circle"),
                Macro(label: "Finder", type: .keystroke, value: "command+space", iconName: "magnifyingglass"),
                Macro(label: "Terminal", type: .shellScript, value: "open -a Terminal", iconName: "terminal.fill")
            ])
            
            let vsCode = Profile(name: "VS Code", macros: [
                Macro(label: "Command Palette", type: .keystroke, value: "command+shift+p", iconName: "terminal"),
                Macro(label: "Format", type: .keystroke, value: "shift+option+f", iconName: "doc.text")
            ], associatedBundleIds: ["com.microsoft.VSCode"])
            
            let safari = Profile(name: "Safari", macros: [
                Macro(label: "New Tab", type: .keystroke, value: "command+t", iconName: "plus.square"),
                Macro(label: "Close Tab", type: .keystroke, value: "command+w", iconName: "xmark.square"),
                Macro(label: "History", type: .keystroke, value: "command+y", iconName: "clock"),
                Macro(label: "Downloads", type: .keystroke, value: "command+option+l", iconName: "arrow.down.circle")
            ], associatedBundleIds: ["com.apple.Safari", "com.google.Chrome"])
            
            self.profiles = [global, vsCode, safari]
            save() // Save these defaults immediately so they persist
        }
        
        // Set active profile
        if let global = self.profiles.first(where: { $0.name == "Global" }) {
            self.activeProfile = global
        } else {
            self.activeProfile = self.profiles.first
        }
    }
    
    func switchToProfile(named name: String) {
        if let profile = profiles.first(where: { $0.name == name }) {
            activeProfile = profile
        } else {
            // Fallback to Global if specific profile not found
            if let global = profiles.first(where: { $0.name == "Global" }) {
                activeProfile = global
            }
        }
    }
    
    func activateProfile(for bundleId: String) {
        // Find profile that contains this bundleId
        // If multiple match, pick first.
        // If bundleId is empty, or none match, revert to Global? 
        // Or keep current if manual switch?
        // Requirement: "if safari is open it should show safari specific macros"
        
        if let match = profiles.first(where: { $0.associatedBundleIds.contains(bundleId) }) {
            activeProfile = match
        } else {
            // Revert to Global only if we were auto-switched? 
            // For simplicity, yes, default back to Global when app changes to something unknown.
            if let global = profiles.first(where: { $0.name == "Global" }) {
                activeProfile = global
            }
        }
    }
    
    func cycleNextProfile() {
        guard !profiles.isEmpty, let current = activeProfile else { return }
        if let index = profiles.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (index + 1) % profiles.count
            activeProfile = profiles[nextIndex]
        }
    }
    
    // MARK: - CRUD
    
    func save() {
        PersistenceManager.shared.saveProfiles(self.profiles)
        // Refresh active profile if it was modified
        if let active = activeProfile, let updated = profiles.first(where: { $0.id == active.id }) {
            activeProfile = updated
        }
    }
    
    func updateProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            save()
        }
    }
    
    func addProfile(name: String) {
        let newProfile = Profile(name: name, macros: [])
        profiles.append(newProfile)
        save()
    }
    
    func deleteProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles.remove(at: index)
            save()
        }
    }
    
    func deleteProfile(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        save()
    }
    
    // MARK: - Import/Export
    
    func exportProfile(_ profile: Profile, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(profile)
            try data.write(to: url)
            print("Exported profile '\(profile.name)' to: \(url.path)")
        } catch {
            print("Failed to export profile: \(error)")
        }
    }
    
    func importProfile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            var importedProfile = try decoder.decode(Profile.self, from: data)
            
            // Generate new IDs to prevent collisions if imported on the same machine
            importedProfile.id = UUID()
            for i in 0..<importedProfile.macros.count {
                importedProfile.macros[i].id = UUID()
            }
            
            // Add suffix if name exists
            var uniqueName = importedProfile.name
            var counter = 1
            while profiles.contains(where: { $0.name == uniqueName }) {
                uniqueName = "\(importedProfile.name) \(counter)"
                counter += 1
            }
            importedProfile.name = uniqueName
            
            profiles.append(importedProfile)
            save()
            
            // Automatically switch to the imported profile
            activeProfile = importedProfile
        } catch {
            print("Failed to import profile: \(error)")
        }
    }
}
