import SwiftUI
import AppKit

struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleId: String
    let icon: NSImage
    let url: URL
}

class AppScanner: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isLoading = false
    
    private var query = NSMetadataQuery()
    
    func startScan() {
        isLoading = true
        apps = []
        
        // Stop any existing query
        query.stop()
        
        // Setup query for applications
        query.predicate = NSPredicate(format: "kMDItemContentType == 'com.apple.application-bundle'")
        query.searchScopes = ["/Applications", "/System/Applications", NSMetadataQueryUserHomeScope]
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidFinish(_:)),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )
        
        query.start()
    }
    
    @objc private func queryDidFinish(_ notification: Notification) {
        query.stop()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var foundApps: [AppInfo] = []
            
            // Enumerate results
            for result in self.query.results {
                if let item = result as? NSMetadataItem,
                   let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                   let bundleId = item.value(forAttribute: "kMDItemCFBundleIdentifier") as? String {
                    
                    let url = URL(fileURLWithPath: path)
                    let name = FileManager.default.displayName(atPath: path)
                    let icon = NSWorkspace.shared.icon(forFile: path)
                    
                    let app = AppInfo(name: name, bundleId: bundleId, icon: icon, url: url)
                    foundApps.append(app)
                }
            }
            
            // Remove duplicates (by bundleId), prefer shorter paths (usually /Applications over others)
            let uniqueApps = Dictionary(grouping: foundApps, by: { $0.bundleId })
                .compactMap { $0.value.first }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.apps = uniqueApps
                self.isLoading = false
            }
        }
    }
}

struct AppSelectionView: View {
    @Environment(\.dismiss) var dismiss
    var onSelect: (String) -> Void
    
    @StateObject private var scanner = AppScanner()
    @State private var searchText = ""
    
    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return scanner.apps
        } else {
            return scanner.apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Select an App to Link")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search Applications...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // List
            if scanner.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning Apps...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List(filteredApps) { app in
                    Button(action: {
                        onSelect(app.bundleId)
                        dismiss()
                    }) {
                        HStack {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading) {
                                Text(app.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(.plain)
            }
            
            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 350, height: 500)
        .onAppear {
            scanner.startScan()
        }
    }
}
