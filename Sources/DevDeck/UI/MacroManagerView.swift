import SwiftUI

struct MacroManagerView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var selectedProfile: Profile?
    
    // Sync
    @State private var showSyncAlert = false
    @State private var syncURLString = "https://raw.githubusercontent.com/your-org/profiles/main/profiles.json"
    
    // App Picker
    @State private var showAppPicker = false
    
    // Drag & Drop
    @State private var draggingMacro: Macro?
    
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
            // Look up the live profile from the manager to ensure we have the latest data
            if let selected = selectedProfile,
               let index = profileManager.profiles.firstIndex(where: { $0.id == selected.id }) {
                
                // Create a binding for convenience where needed, or access the manager directly
                let profile = profileManager.profiles[index]
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. TOP SECTION: LIVE PREVIEW
                        VStack {
                            Text("Live Preview")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // We reuse RadialMenuView but pass a read-only or dummy action
                            // Pass 'profile' (the one being edited) as the preview
                            RadialMenuView(profileManager: profileManager, previewProfile: profile, onExecute: { _ in })
                                .frame(width: 450, height: 450) // Increased from 300 to fit new 170pt radius
                                .scaleEffect(0.8) // Scale down to fit in the UI nicely
                                .background(Color.black.opacity(0.8)) // Dark preview background
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .environment(\.colorScheme, .dark) // Force dark mode for preview
                        }
                        .padding()
                        
                        Divider()
                        
                        // 2. PROFILE SETTINGS (Linked Apps)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Linked Apps")
                                    .font(.headline)
                                Spacer()
                                Button(action: { showAppPicker = true }) {
                                    Label("Add App", systemImage: "plus")
                                }
                                .popover(isPresented: $showAppPicker) {
                                    AppSelectionView { bundleId in
                                        // Update the Live Profile directly
                                        if !profileManager.profiles[index].associatedBundleIds.contains(bundleId) {
                                            profileManager.profiles[index].associatedBundleIds.append(bundleId)
                                        }
                                        showAppPicker = false
                                    }
                                }
                            }
                            
                            if profile.associatedBundleIds.isEmpty {
                                Text("No apps linked. This profile will only be active when selected manually.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
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
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                 profileManager.profiles[index].associatedBundleIds.removeAll(where: { $0 == bundleId })
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(8)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        Divider()
                        
                        // 3. BOTTOM SECTION: MACRO GRIDS
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Macros")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    let newMacro = Macro(
                                        label: "New Macro",
                                        type: .shellScript,
                                        value: "echo 'Hello World'",
                                        iconName: "star"
                                    )
                                    // Make sure we update the specific profile in the manager
                                    withAnimation {
                                        profileManager.profiles[index].macros.append(newMacro)
                                    }
                                }) {
                                    Label("Add Macro", systemImage: "plus.circle.fill")
                                        .font(.body.bold())
                                }
                                .buttonStyle(.borderedProminent) // Make it POP
                            }
                            .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 16) {
                                ForEach($profileManager.profiles[index].macros) { $macro in
                                    MacroConfigCard(macro: $macro)
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
                            .padding()
                        }
                    }
                    .padding(.bottom, 40)
                }
                .navigationTitle($profileManager.profiles[index].name) // Editable Title in Navbar (macOS 14+)? 
                // Or just separate TextField. NavigationTitle binding is simplest if supported, but let's be safe.
                .toolbar {
                     ToolbarItem(placement: .principal) {
                         TextField("Profile Name", text: $profileManager.profiles[index].name)
                             .font(.headline)
                             .frame(width: 200)
                             .multilineTextAlignment(.center)
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
                        // Stub sync
                        print("Syncing from \(syncURLString)...")
                    }
                }
            } else {
                Text("Select a Profile to Edit")
                    .font(.title)
                    .foregroundColor(.secondary)
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
