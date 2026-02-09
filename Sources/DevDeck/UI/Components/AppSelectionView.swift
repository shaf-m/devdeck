import SwiftUI
import AppKit

struct AppSelectionView: View {
    @Environment(\.dismiss) var dismiss
    var onSelect: (String) -> Void
    
    @State private var runningApps: [NSRunningApplication] = []
    
    var body: some View {
        VStack {
            Text("Select an App to Link")
                .font(.headline)
                .padding(.top)
            
            List(runningApps, id: \.bundleIdentifier) { app in
                Button(action: {
                    if let id = app.bundleIdentifier {
                        onSelect(id)
                        dismiss()
                    }
                }) {
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                        VStack(alignment: .leading) {
                            Text(app.localizedName ?? "Unknown App")
                                .font(.body)
                            Text(app.bundleIdentifier ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 300, height: 400)
            
            Button("Cancel") {
                dismiss()
            }
            .padding(.bottom)
        }
        .onAppear(perform: loadApps)
    }
    
    private func loadApps() {
        let apps = NSWorkspace.shared.runningApplications
        self.runningApps = apps.filter { app in
            // Filter out agents/daemons and apps without bundle IDs
            guard let _ = app.bundleIdentifier else { return false }
            return app.activationPolicy == .regular
        }.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
}
