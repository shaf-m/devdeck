import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Quick Start")) {
                    Button(action: { showOnboarding = true }) {
                        Label("Replay Welcome Tour", systemImage: "arrow.counterclockwise.circle")
                    }
                    .buttonStyle(.plain)
                }
                
                Section(header: Text("Tutorials")) {
                    NavigationLink(destination: TutorialDetailView(
                        title: "Creating Macros",
                        icon: "plus.square.fill",
                        color: .green,
                        content: "To create a macro, navigate to a profile and click the **+ Add Macro** button.\n\nChoose a label, an icon (SF Symbol name), and the type of action you want to perform:\n• **Keystroke**: Simulate key presses (e.g., Cmd+C)\n• **Text/Paste**: Insert snippets of code\n• **Shell Script**: Run terminal commands\n• **Open URL**: Launch websites"
                    )) {
                        Label("Creating Macros", systemImage: "plus.square")
                    }
                    
                    NavigationLink(destination: TutorialDetailView(
                        title: "Context Switching",
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        color: .blue,
                        content: "DevDeck detects the active window.\n\nYou can link profiles to specific applications by adding their **Bundle IDs** (e.g., `com.apple.Safari`) in the Profile Details view.\n\nWhen you switch focus to that app, DevDeck automatically activates the corresponding profile."
                    )) {
                        Label("Context Switching", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    NavigationLink(destination: TutorialDetailView(
                        title: "The Radial Menu",
                        icon: "circle.circle.fill",
                        color: .purple,
                        content: "The overlay window appears when you trigger it (Default: `Cmd` long press or configured shortcut).\n\nUse your mouse to hover over items towards the edges of the circle to select them. Release the mouse button or key to execute."
                    )) {
                        Label("Using the Radial Menu", systemImage: "circle.circle")
                    }
                }
                
                Section(header: Text("Troubleshooting")) {
                    NavigationLink(destination: TutorialDetailView(
                        title: "Overlay Not Showing?",
                        icon: "exclamationmark.triangle.fill",
                        color: .yellow,
                        content: "**1. Check Permissions**: Ensure Accessibility permissions are enabled for DevDeck in System Settings.\n\n**2. Check App Status**: Ensure the application is running (icon in menu bar).\n\n**3. Restart App**: Sometimes a restart is required after granting permissions."
                    )) {
                        Label("Overlay Not Showing?", systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Help Topics")
        } detail: {
            VStack(spacing: 20) {
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.2))
                Text("Select a topic to view details")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
}

struct TutorialDetailView: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(color)
                    Text(title)
                        .font(.largeTitle)
                        .bold()
                }
                .padding(.bottom, 10)
                
                Divider()
                
                Text(try! AttributedString(markdown: content)) // Basic markdown support
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(40)
        }
    }
}
