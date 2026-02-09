import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let fileManager = FileManager.default
    private let fileName = "profiles.json"
    
    private var profilesURL: URL? {
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let devDeckURL = appSupportURL.appendingPathComponent("DevDeck")
        
        // Ensure directory exists
        if !fileManager.fileExists(atPath: devDeckURL.path) {
            do {
                try fileManager.createDirectory(at: devDeckURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create Application Support directory: \(error)")
                return nil
            }
        }
        
        return devDeckURL.appendingPathComponent(fileName)
    }
    
    func saveProfiles(_ profiles: [Profile]) {
        guard let url = profilesURL else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(profiles)
            try data.write(to: url)
            print("Saved profiles to: \(url.path)")
        } catch {
            print("Failed to save profiles: \(error)")
        }
    }
    
    func loadProfiles() -> [Profile] {
        guard let url = profilesURL else { return loadDefaults() }
        
        if fileManager.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let profiles = try decoder.decode([Profile].self, from: data)
                print("Loaded profiles from: \(url.path)")
                return profiles
            } catch {
                print("Failed to load profiles form app support: \(error)")
                // Fallback
                return loadDefaults()
            }
        } else {
            return loadDefaults()
        }
    }
    
    private func loadDefaults() -> [Profile] {
        guard let url = Bundle.main.url(forResource: "default_profiles", withExtension: "json") else {
            print("Could not find default_profiles.json")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let profiles = try decoder.decode([Profile].self, from: data)
            return profiles
        } catch {
            print("Failed to decode existing default profiles: \(error)")
            return []
        }
    }
}
