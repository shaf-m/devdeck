import Foundation

enum MacroType: String, Codable, CaseIterable {
    case shellScript
    case appleScript
    case url
    case keystroke
    case text
}

struct Macro: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var label: String
    var type: MacroType
    var value: String
    var iconName: String?
    var pressEnter: Bool = false
    
    // ... (rest of implementation)
}

struct Profile: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var macros: [Macro]
    var associatedBundleIds: [String] = []
    
    enum CodingKeys: String, CodingKey {
        case id, name, macros, associatedBundleIds
    }
    
    // Init for decoding with default
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.macros = try container.decode([Macro].self, forKey: .macros)
        self.associatedBundleIds = try container.decodeIfPresent([String].self, forKey: .associatedBundleIds) ?? []
    }
    
    init(name: String, macros: [Macro], associatedBundleIds: [String] = []) {
        self.id = UUID()
        self.name = name
        self.macros = macros
        self.associatedBundleIds = associatedBundleIds
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(macros, forKey: .macros)
        try container.encode(associatedBundleIds, forKey: .associatedBundleIds)
    }
}
