import SwiftUI

struct MacroManagerView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var selectedProfile: Profile?
    
    // Sync
    @State private var showSyncAlert = false
    @State private var syncURLString = "https://raw.githubusercontent.com/your-org/profiles/main/profiles.json"
    
    // App Picker
    @State private var showAppPicker = false
    
    // UI State
    @State private var showSnippetLibrary = false
    
    // Drag & Drop
    @State private var draggingMacro: Macro?
    @State private var macroToDelete: Macro?
    @State private var showDeleteConfirmation = false
    
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
                .onDelete(perform: deleteProfile)
            }
            .navigationTitle("Profiles")
            .toolbar {
                Button(action: addProfile) {
                    Label("Add Profile", systemImage: "plus")
                }
            }
        } detail: {
            // MAIN CANVAS
            if let selected = selectedProfile,
               let index = profileManager.profiles.firstIndex(where: { $0.id == selected.id }) {
                profileDetailView(index: index)
            } else {
                Text("Select a Profile to Edit")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .inspector(isPresented: $showSnippetLibrary) {
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
    
    // Extracted detail view to reduce compiler complexity
    @ViewBuilder
    private func profileDetailView(index: Int) -> some View {
        let profile = profileManager.profiles[index]
        
        ScrollView {
            VStack(spacing: 24) {
                // 1. TOP SECTION: LIVE PREVIEW
                VStack(spacing: 8) {
                    HStack {
                        Text("Live Preview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ZStack {
                        // Deck Bezel
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .frame(width: 480, height: 480)
                        
                        // Screen
                        RadialMenuView(profileManager: profileManager, previewProfile: profile, onExecute: { _ in })
                            .frame(width: 450, height: 450)
                            .scaleEffect(0.85)
                            .background(Color.black)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                            )
                            .environment(\.colorScheme, .dark)
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
                 TextField("Profile Name", text: $profileManager.profiles[index].name)
                     .font(.headline)
                     .frame(width: 200)
                     .multilineTextAlignment(.center)
             }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { showSnippetLibrary.toggle() }) {
                    Label("Snippets", systemImage: "curlybraces")
                }
            }

            ToolbarItem(placement: .automatic) {
                Button(action: { showSyncAlert = true }) {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        .alert("Sync Profiles", isPresented: $showSyncAlert) {
            TextField("URL", text: $syncURLString)
            Button("Cancel", role: .cancel) { }
            Button("Sync") {
                print("Syncing from \(syncURLString)...")
            }
        }
    }
    
    private func linkedAppsSection(profile: Profile, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    Label("Link App", systemImage: "plus")
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
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
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                    ForEach(profile.associatedBundleIds, id: \.self) { bundleId in
                        HStack {
                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "app")
                                    .frame(width: 24, height: 24)
                            }
                            
                            Text(nameForBundleId(bundleId))
                                .font(.caption)
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
                        .padding(10)
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
                
                Button(action: {
                    let newMacro = Macro(
                        label: "New Macro",
                        type: .shellScript,
                        value: "echo 'Hello World'",
                        iconName: "star"
                    )
                    withAnimation {
                        profileManager.profiles[index].macros.append(newMacro)
                    }
                }) {
                    Label("Add Macro", systemImage: "plus")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
                            MacroConfigCard(macro: $macro) {
                                macroToDelete = macro
                                showDeleteConfirmation = true
                            }
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
                        
                        // Try to parse as Snippet JSON
                        if let data = jsonString.data(using: .utf8),
                           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                           dict["type"] == "snippet",
                           let name = dict["name"],
                           let content = dict["content"] {
                            
                            if self.draggingMacro == nil {
                                let newMacro = Macro(
                                    label: name,
                                    type: .text, // Requested: text/paste
                                    value: content,
                                    iconName: "doc.text.fill"
                                )
                                withAnimation {
                                    profileManager.profiles[index].macros.append(newMacro)
                                }
                            }
                        } else {
                            // Fallback for raw text
                            if self.draggingMacro == nil {
                                let newMacro = Macro(
                                    label: "New Text Macro",
                                    type: .text,
                                    value: jsonString,
                                    iconName: "doc.text"
                                )
                                withAnimation {
                                    profileManager.profiles[index].macros.append(newMacro)
                                }
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
    
    private func addProfile() {
        profileManager.addProfile(name: "New Profile")
    }
    
    private func deleteProfile(at offsets: IndexSet) {
        profileManager.deleteProfile(at: offsets)
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
