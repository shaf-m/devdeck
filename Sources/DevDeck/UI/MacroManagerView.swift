import SwiftUI

struct MacroManagerView: View {
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var clipboardManager: ClipboardHistoryManager
    @State private var selectedProfile: Profile?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showHelp = false
    

    
    // App Picker
    @State private var showAppPicker = false
    
    // UI State
    @State private var showSnippetLibrary = false
    @State private var showQuickAdd = false
    
    // Drag & Drop
    @State private var draggingMacro: Macro?
    @State private var macroToDelete: Macro?
    @State private var showDeleteConfirmation = false
    
    // Profile Deletion
    @State private var showProfileDeleteConfirmation = false
    @State private var profileToDeleteIndex: IndexSet?
    
    // Profile Renaming
    @State private var isEditingProfileName = false
    
    // New Macro Tracking
    @State private var newMacroID: UUID?
    
    // Helper to get app name
    func nameForBundleId(_ bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return FileManager.default.displayName(atPath: url.path)
        }
        return bundleId
    }
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR
            VStack(spacing: 0) {
                // Logo Area
                HStack {
                    Text("<DevDeck>")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                }
                .padding()
                .padding(.top, 8)
                
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
                    .onDelete(perform: confirmDeleteProfile)
                }
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 400)
            }
            .navigationTitle("Profiles")
            .toolbar {
                Button(action: importProfile) {
                    Label("Import Profile", systemImage: "square.and.arrow.down")
                }
                .help("Import Profile from JSON")
                
                Button(action: { showHelp = true }) {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .help("Help & Tutorials")
                
                Button(action: addProfile) {
                    Label("Add Profile", systemImage: "plus")
                }
                .help("Create New Profile")
            }
        } detail: {
            // MAIN CANVAS
            if let selected = selectedProfile,
               let index = profileManager.profiles.firstIndex(where: { $0.id == selected.id }) {
                profileDetailView(index: index)
            } else {
                VStack(spacing: 20) {
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("<DevDeck>")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Select or create a profile to begin")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    Button("Help & Tutorials") {
                        showHelp = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { hasCompletedOnboarding = !$0 }
        )) {
            OnboardingView(isPresented: Binding(
                get: { !hasCompletedOnboarding },
                set: { hasCompletedOnboarding = !$0 }
            ))
            .interactiveDismissDisabled()
        }
        .inspector(isPresented: Binding(
            get: { showSnippetLibrary || showQuickAdd },
            set: { if !$0 { showSnippetLibrary = false; showQuickAdd = false } }
        )) {
            if showQuickAdd {
                QuickAddSidebarView(onAdd: { macro in
                    if let selected = selectedProfile,
                       let index = profileManager.profiles.firstIndex(where: { $0.id == selected.id }) {
                            withAnimation {
                                profileManager.profiles[index].macros.append(macro)
                                highlightNewMacro(macro)
                            }
                    }
                }, onClose: {
                    showQuickAdd = false
                })
                .frame(minWidth: 260)
            } else {
                SnippetLibraryView()
                    .frame(minWidth: 250)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: { showSnippetLibrary = false }) {
                                Label("Close", systemImage: "sidebar.right")
                            }
                        }
                    }
            }
        }
        .alert("Delete Profile?", isPresented: $showProfileDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                profileToDeleteIndex = nil
            }
            Button("Delete", role: .destructive) {
                deleteProfile()
            }
        } message: {
            Text("Are you sure you want to delete this profile? This cannot be undone.")
        }
    }
    
    // Extracted detail view to reduce compiler complexity
    @ViewBuilder
    private func profileDetailView(index: Int) -> some View {
        let profile = profileManager.profiles[index]
        
        ScrollView {
            VStack(spacing: 24) {
                // 1. TOP SECTION: LIVE PREVIEW
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Live Preview")
                                .font(.title3)
                                .bold()
                            Text("Interact with the radial menu to test navigation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    ZStack {
                        // Deck Bezel
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .frame(width: 480, height: 480)
                        
                        // Screen
                        RadialMenuView(profileManager: profileManager, clipboardManager: clipboardManager, previewProfile: profile, onExecute: { _ in }, circlePadding: 5)
                            .frame(width: 450, height: 450)
                            .scaleEffect(0.85)
                            .background(Color.clear)
                    }
                    .padding()
                }
                
                Divider()
                
                // 2. PROFILE SETTINGS
                linkedAppsSection(profile: profile, index: index)
                
                Divider()
                
                // 3. MACROS GRID
                macrosGridSection(index: index)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle($profileManager.profiles[index].name)
        .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        if isEditingProfileName {
                            TextField("Profile Name", text: $profileManager.profiles[index].name)
                                .font(.headline)
                                .frame(width: 200)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    isEditingProfileName = false
                                }
                            
                            Button(action: { isEditingProfileName = false }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.plain)
                            .help("Save Name")
                        } else {
                            Text(profileManager.profiles[index].name)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Button(action: { isEditingProfileName = true }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Rename Profile")
                        }
                    }
                }
            
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 0) {
                    Button(action: {
                        showQuickAdd = false
                        showSnippetLibrary.toggle()
                    }) {
                        Label("Snippets", systemImage: "curlybraces")
                            .foregroundColor(showSnippetLibrary ? .blue : .primary)
                    }
                    .help("Show Snippet Library")
                    
                    Button(action: {
                        showSnippetLibrary = false
                        showQuickAdd.toggle()
                    }) {
                        Label("Quick Add", systemImage: "wand.and.stars")
                             .foregroundColor(showQuickAdd ? .blue : .primary)
                    }
                    .help("Show Quick Add")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive, action: {
                    confirmDeleteProfile(at: IndexSet(integer: index))
                }) {
                    Label("Delete Profile", systemImage: "trash")
                }
                .disabled(profileManager.profiles[index].name == "Global")
                .help("Delete Profile")
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { exportProfile(profile) }) {
                    Label("Export Profile", systemImage: "square.and.arrow.up")
                }
                .help("Export Profile to JSON")
            }


        }

    }
    
    private func linkedAppsSection(profile: Profile, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if profile.name.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("Global") == .orderedSame {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Global Profile")
                        .font(.title3)
                        .bold()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("This is your default profile. It will be active when DevDeck is triggered on an app that doesn't have a specific profile assigned.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Linked Apps")
                            .font(.title3)
                            .bold()
                        Text("Profile becomes active when these apps are focused")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showAppPicker = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Link App")
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showAppPicker) {
                        AppSelectionView { bundleId in
                            if !profileManager.profiles[index].associatedBundleIds.contains(bundleId) {
                                withAnimation {
                                    profileManager.profiles[index].associatedBundleIds.append(bundleId)
                                }
                            }
                            showAppPicker = false
                        }
                    }
                }
                
                if profile.associatedBundleIds.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "app.dashed")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("No apps linked. This profile will only be active when selected manually.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
                        ForEach(profile.associatedBundleIds, id: \.self) { bundleId in
                            HStack {
                                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "app")
                                        .frame(width: 32, height: 32)
                                }
                                
                                Text(nameForBundleId(bundleId))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        profileManager.profiles[index].associatedBundleIds.removeAll(where: { $0 == bundleId })
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .onHover { inside in
                                    if inside { NSCursor.pointingHand.push() }
                                    else { NSCursor.pop() }
                                }
                            }
                            .padding(14)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func macrosGridSection(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Macros")
                        .font(.title3)
                        .bold()
                    Text("Drag to reorder • Drop snippets to add")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        let newMacro = Macro(
                            label: "New Macro",
                            type: .shellScript,
                            value: "echo 'Hello World'",
                            iconName: "star"
                        )
                        withAnimation {
                            profileManager.profiles[index].macros.append(newMacro)
                            highlightNewMacro(newMacro)
                        }
                    }) {
                        GradientMenuLabel(text: "Custom Macro", systemImage: "plus.square")
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showSnippetLibrary = false
                        showQuickAdd = true
                    }) {
                        GradientMenuLabel(text: "Quick Add", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            Group {
                if profileManager.profiles[index].macros.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "command.square")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No Macros Configured")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add a macro to get started, or drag snippets from the library.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(16)
                    .padding(.horizontal)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                        ForEach($profileManager.profiles[index].macros) { $macro in
                            MacroConfigCard(
                                macro: $macro,
                                onDelete: {
                                    macroToDelete = macro
                                    showDeleteConfirmation = true
                                },
                                onEdit: {
                                    if newMacroID == macro.id {
                                        withAnimation { newMacroID = nil }
                                    }
                                },
                                isNew: newMacroID == macro.id
                            )
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let mIndex = profileManager.profiles[index].macros.firstIndex(where: { $0.id == $macro.id }) {
                                        withAnimation {
                                            _ = profileManager.profiles[index].macros.remove(at: mIndex)
                                        }
                                    }
                                } label: {
                                    Label("Delete Macro", systemImage: "trash")
                                }
                            }
                            // Drag and Drop Logic
                            .onDrag {
                                self.draggingMacro = macro
                                return NSItemProvider(object: macro.id.uuidString as NSString)
                            }
                            .onDrop(of: [.text], delegate: MacroDragRelocateDelegate(item: macro, listData: $profileManager.profiles[index].macros, current: $draggingMacro))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            // Drop zone for Snippets
            .onDrop(of: [.text], isTargeted: nil) { providers in
                guard let first = providers.first else { return false }
                _ = first.loadObject(ofClass: NSString.self) { string, error in
                    DispatchQueue.main.async {
                        guard let jsonString = string as? String else { return }
                        
                        // Try to parse as JSON
                        if let data = jsonString.data(using: .utf8),
                           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let type = dict["type"] as? String {
                            
                            // Case 1: Quick Add Macro
                            if type == "macro_json",
                               let label = dict["label"] as? String,
                               let macroTypeRaw = dict["macroType"] as? String,
                               let macroType = MacroType(rawValue: macroTypeRaw),
                               let value = dict["value"] as? String,
                               let iconName = dict["iconName"] as? String {
                                
                                if self.draggingMacro == nil {
                                    let newMacro = Macro(
                                        label: label,
                                        type: macroType,
                                        value: value,
                                        iconName: iconName
                                    )
                                    withAnimation {
                                        profileManager.profiles[index].macros.append(newMacro)
                                        highlightNewMacro(newMacro)
                                    }
                                }
                                return
                            }
                            
                            // Case 2: Snippet (type == "snippet")
                            if type == "snippet",
                               let name = dict["name"] as? String,
                               let content = dict["content"] as? String {
                                
                                if self.draggingMacro == nil {
                                    let newMacro = Macro(
                                        label: name,
                                        type: .text,
                                        value: content,
                                        iconName: "doc.text.fill"
                                    )
                                    withAnimation {
                                        profileManager.profiles[index].macros.append(newMacro)
                                        highlightNewMacro(newMacro)
                                    }
                                }
                                return
                            }
                        }
                        
                        // Fallback handling (outside the JSON block essentially)
                        // If we reached here, it wasn't a recognized JSON drop
                        if self.draggingMacro == nil {
                             // Only treat as text if it DOESN'T look like our internal JSON
                            // Simple heuristic: if it starts with { and ends with }, assume it's failed JSON and ignore?
                            // Or just treat as text.
                            // The previous code would treat valid JSON snippets as text if parsing failed, but we want to be robust.
                            
                            let newMacro = Macro(
                                label: "New Text Macro",
                                type: .text,
                                value: jsonString,
                                iconName: "doc.text"
                            )
                            withAnimation {
                                profileManager.profiles[index].macros.append(newMacro)
                                highlightNewMacro(newMacro)
                            }
                        }
                    }
                }
                return true
            }
            .alert("Delete Macro?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    macroToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let macro = macroToDelete {
                        DispatchQueue.main.async {
                            if let mIndex = profileManager.profiles[index].macros.firstIndex(where: { $0.id == macro.id }) {
                                withAnimation {
                                    _ = profileManager.profiles[index].macros.remove(at: mIndex)
                                }
                            }
                            macroToDelete = nil
                        }
                    } else {
                        macroToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(macroToDelete?.label ?? "this macro")'? This action cannot be undone.")
            }
        }
    }
    

    
    private func highlightNewMacro(_ macro: Macro) {
        self.newMacroID = macro.id
        // Auto-hide after 60 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            if self.newMacroID == macro.id {
                withAnimation {
                    self.newMacroID = nil
                }
            }
        }
    }
    
    private func addProfile() {
        profileManager.addProfile(name: "New Profile")
    }
    
    private func confirmDeleteProfile(at offsets: IndexSet) {
        profileToDeleteIndex = offsets
        showProfileDeleteConfirmation = true
    }
    
    private func deleteProfile() {
        if let offsets = profileToDeleteIndex {
            profileManager.deleteProfile(at: offsets)
            if selectedProfile != nil && !profileManager.profiles.contains(where: { $0.id == selectedProfile?.id }) {
                selectedProfile = nil
            }
        }
        profileToDeleteIndex = nil
    }
    
    // MARK: - Import/Export Helpers
    
    private func exportProfile(_ profile: Profile) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Export Profile"
        savePanel.message = "Choose where to save your profile backup"
        savePanel.nameFieldStringValue = "\(profile.name).json"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                profileManager.exportProfile(profile, to: url)
            }
        }
    }
    
    private func importProfile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Import Profile"
        openPanel.message = "Choose a DevDeck profile JSON file to import"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                profileManager.importProfile(from: url)
                // Update selection to the new profile if it was set as active
                if let newActive = profileManager.activeProfile {
                    selectedProfile = newActive
                }
            }
        }
    }
}

// Re-implementation of DropDelegate for robust reordering requires a bit more.
// Let's try the DragRelocateDelegate pattern.

struct MacroDragRelocateDelegate: DropDelegate {
    let item: Macro
    @Binding var listData: [Macro]
    @Binding var current: Macro?

    func dropEntered(info: DropInfo) {
        if let current = current, current != item {
            let from = listData.firstIndex(of: current)!
            let to = listData.firstIndex(of: item)!
            if listData[to].id != current.id {
                withAnimation {
                    listData.move(fromOffsets: IndexSet(integer: from),
                                  toOffset: to > from ? to + 1 : to)
                }
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
}

struct GradientMenuLabel: View {
    let text: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.headline)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .padding(.horizontal, 20)
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
}
