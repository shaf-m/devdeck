import SwiftUI

struct DashboardView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var selectedProfile: Profile?
    @State private var editingMacro: Macro?
    @State private var isEditingMacro = false
    @State private var showNewProfileAlert = false
    @State private var newProfileName = ""
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedProfile) {
                ForEach(profileManager.profiles) { profile in
                    NavigationLink(value: profile) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(profile.name)
                                .fontWeight(profile.name == "Global" ? .bold : .regular)
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteProfiles(at: indexSet)
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                Button(action: { showNewProfileAlert = true }) {
                    Label("Add Profile", systemImage: "plus")
                }
            }
            .alert("New Profile", isPresented: $showNewProfileAlert) {
                TextField("Profile Name", text: $newProfileName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    profileManager.addProfile(name: newProfileName)
                    newProfileName = ""
                }
            }
        } detail: {
            if let profile = selectedProfile {
                ProfileDetailView(profile: profile, profileManager: profileManager)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("Select a Profile")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("Manage your macros and linked apps here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = profileManager.profiles[index]
            profileManager.deleteProfile(profile)
        }
    }
}

struct ProfileDetailView: View {
    var profile: Profile
    @ObservedObject var profileManager: ProfileManager
    @State private var macros: [Macro] = []
    @State private var selectedMacro: Macro?
    @State private var showMacroEditor = false
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Linked Apps")) {
                    ForEach(profile.associatedBundleIds, id: \.self) { bundleId in
                        Text(bundleId)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .onDelete(perform: deleteBundleId)
                    
                    HStack {
                        TextField("com.example.app", text: $newBundleId)
                        Button("Add") {
                            addBundleId()
                        }
                        .disabled(newBundleId.isEmpty)
                    }
                }
                
                Section(header: Text("Macros")) {
                    ForEach(macros) { macro in
                        HStack {
                            Image(systemName: macro.iconName ?? "gear")
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text(macro.label)
                                    .font(.headline)
                                Text(macro.value)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if macro.type == .text {
                                Image(systemName: "text.quote")
                                    .foregroundColor(.blue)
                            } else if macro.type == .keystroke {
                                Image(systemName: "keyboard")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMacro = macro
                            showMacroEditor = true
                        }
                    }
                    .onMove(perform: moveMacros)
                    .onDelete(perform: deleteMacros)
                }
            }
            .listStyle(.inset)
        }
        .navigationTitle(profile.name)
        .toolbar {
            Button(action: {
                selectedMacro = nil // New macro
                showMacroEditor = true
            }) {
                Label("Add Macro", systemImage: "plus")
            }
        }
        .onAppear {
            self.macros = profile.macros
        }
        .onChange(of: profile) {
            self.macros = profile.macros
            // we don't need to sync bundleIds manually here as they come from profile
        }
        .sheet(isPresented: $showMacroEditor) {
            MacroEditorView(macro: selectedMacro, onSave: { newMacro in
                if let selected = selectedMacro {
                    // Update
                    if let index = macros.firstIndex(where: { $0.id == selected.id }) {
                        macros[index] = newMacro
                    }
                } else {
                    // Create
                    macros.append(newMacro)
                }
                saveChanges()
            })
        }
    }
    
    @State private var newBundleId: String = ""
    
    func addBundleId() {
        var updatedIds = profile.associatedBundleIds
        if !updatedIds.contains(newBundleId) {
            updatedIds.append(newBundleId)
            let newProfile = Profile(name: profile.name, macros: macros, associatedBundleIds: updatedIds)
            profileManager.updateProfile(newProfile)
            newBundleId = ""
        }
    }
    
    func deleteBundleId(at offsets: IndexSet) {
        var updatedIds = profile.associatedBundleIds
        updatedIds.remove(atOffsets: offsets)
        let newProfile = Profile(name: profile.name, macros: macros, associatedBundleIds: updatedIds)
        profileManager.updateProfile(newProfile)
    }
    
    func moveMacros(from source: IndexSet, to destination: Int) {
        macros.move(fromOffsets: source, toOffset: destination)
        saveChanges()
    }
    
    func deleteMacros(at offsets: IndexSet) {
        macros.remove(atOffsets: offsets)
        saveChanges()
    }
    
    func saveChanges() {
        let newProfile = Profile(name: profile.name, macros: macros, associatedBundleIds: profile.associatedBundleIds)
        profileManager.updateProfile(newProfile)
    }
}

struct MacroEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var label: String = ""
    @State private var type: MacroType = .keystroke
    @State private var value: String = ""
    @State private var iconName: String = "gear"
    @State private var pressEnter: Bool = false
    
    var macro: Macro?
    var onSave: (Macro) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                TextField("Label", text: $label)
                TextField("Icon (SF Symbol)", text: $iconName)
            }
            
            Section(header: Text("Action")) {
                Picker("Type", selection: $type) {
                    Text("Keystroke").tag(MacroType.keystroke)
                    Text("Text / Paste").tag(MacroType.text)
                    Text("Shell Script").tag(MacroType.shellScript)
                    Text("Open URL").tag(MacroType.url)
                }
                
                if type == .text {
                    TextEditor(text: $value)
                        .frame(height: 100)
                    Toggle("Press Enter after typing", isOn: $pressEnter)
                } else {
                    TextField(placeholderForType(type), text: $value)
                }
                
                if type == .keystroke {
                    Toggle("Press Enter after", isOn: $pressEnter)
                }
            }
        }
        .frame(width: 400, height: 400)
        .padding()
        .toolbar {
            Button("Cancel") { dismiss() }
            Button("Save") {
                let newMacro = Macro(
                    id: macro?.id ?? UUID(),
                    label: label,
                    type: type,
                    value: value,
                    iconName: iconName,
                    pressEnter: pressEnter
                )
                onSave(newMacro)
                dismiss()
            }
            .disabled(label.isEmpty || value.isEmpty)
        }
        .onAppear {
            if let m = macro {
                label = m.label
                type = m.type
                value = m.value
                iconName = m.iconName ?? "gear"
                pressEnter = m.pressEnter
            }
        }
    }
    
    func placeholderForType(_ type: MacroType) -> String {
        switch type {
        case .keystroke: return "command+shift+p"
        case .shellScript: return "echo 'Hello'"
        case .appleScript: return "tell application \"Finder\" to activate"
        case .url: return "https://google.com"
        case .text: return "Text content"
        }
    }
}
