import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showOnboarding = false
    @State private var selection: HelpTopic? = .gettingStarted
    
    enum HelpTopic: String, CaseIterable, Identifiable {
        case gettingStarted
        case creatingMacros
        case contextSwitching
        case radialMenu
        case troubleshooting
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .gettingStarted: return "Getting Started"
            case .creatingMacros: return "Creating Macros"
            case .contextSwitching: return "Context Switching"
            case .radialMenu: return "The Radial Menu"
            case .troubleshooting: return "Overlay Not Showing?"
            }
        }
        
        var icon: String {
            switch self {
            case .gettingStarted: return "flag.circle.fill"
            case .creatingMacros: return "plus.square.fill"
            case .contextSwitching: return "arrow.triangle.2.circlepath.circle.fill"
            case .radialMenu: return "circle.circle.fill"
            case .troubleshooting: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .gettingStarted: return .orange
            case .creatingMacros: return .green
            case .contextSwitching: return .blue
            case .radialMenu: return .purple
            case .troubleshooting: return .yellow
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section(header: Text("Quick Start")) {
                    NavigationLink(value: HelpTopic.gettingStarted) {
                        Label(HelpTopic.gettingStarted.title, systemImage: "flag.circle")
                    }
                }
                
                Section(header: Text("Guides")) {
                    NavigationLink(value: HelpTopic.creatingMacros) {
                        Label(HelpTopic.creatingMacros.title, systemImage: "plus.square")
                    }
                    NavigationLink(value: HelpTopic.contextSwitching) {
                        Label(HelpTopic.contextSwitching.title, systemImage: "arrow.triangle.2.circlepath")
                    }
                    NavigationLink(value: HelpTopic.radialMenu) {
                        Label(HelpTopic.radialMenu.title, systemImage: "circle.circle")
                    }
                }
                
                Section(header: Text("Troubleshooting")) {
                    NavigationLink(value: HelpTopic.troubleshooting) {
                        Label(HelpTopic.troubleshooting.title, systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Help")
        } detail: {
            if let selection = selection {
                switch selection {
                case .gettingStarted:
                     VStack(spacing: 30) {
                         Image(systemName: "flag.circle.fill")
                             .font(.system(size: 60))
                             .foregroundColor(.orange)
                         
                         Text("Welcome to DevDeck")
                             .font(.largeTitle)
                             .bold()
                         
                         Text("Get up and running quickly by replaying the welcome tour.")
                             .font(.title2)
                             .foregroundColor(.secondary)
                             .multilineTextAlignment(.center)
                         
                         Button(action: { showOnboarding = true }) {
                             Label("Start Welcome Tour", systemImage: "play.fill")
                                 .font(.headline)
                                 .padding(.horizontal, 20)
                                 .padding(.vertical, 10)
                                 .foregroundColor(.white)
                                 .background(Color.blue)
                                 .cornerRadius(10)
                         }
                         .buttonStyle(.plain)
                         .shadow(radius: 5)
                         
                         Spacer()
                     }
                     .padding(50)
                case .creatingMacros:
                    TutorialDetailView(
                        title: selection.title,
                        icon: selection.icon,
                        color: selection.color,
                        content: "To create a macro, navigate to a profile and click the **+ Add Macro** button.\n\nChoose a label, an icon (SF Symbol name), and the type of action you want to perform:\n• **Keystroke**: Simulate key presses (e.g., Cmd+C)\n• **Text/Paste**: Insert snippets of code\n• **Shell Script**: Run terminal commands\n• **Open URL**: Launch websites"
                    )
                case .contextSwitching:
                    TutorialDetailView(
                        title: selection.title,
                        icon: selection.icon,
                        color: selection.color,
                        content: "DevDeck detects the active window.\n\nYou can link profiles to specific applications by adding their **Bundle IDs** (e.g., `com.apple.Safari`) in the Profile Details view.\n\nWhen you switch focus to that app, DevDeck automatically activates the corresponding profile."
                    )
                case .radialMenu:
                    TutorialDetailView(
                        title: selection.title,
                        icon: selection.icon,
                        color: selection.color,
                        content: "The overlay window appears when you trigger it (Default: `Cmd` long press or configured shortcut).\n\nUse your mouse to hover over items towards the edges of the circle to select them. Release the mouse button or key to execute."
                    )
                case .troubleshooting:
                    TutorialDetailView(
                        title: selection.title,
                        icon: selection.icon,
                        color: selection.color,
                        content: "**1. Check Permissions**: Ensure Accessibility permissions are enabled for DevDeck in System Settings.\n\n**2. Check App Status**: Ensure the application is running (icon in menu bar).\n\n**3. Restart App**: Sometimes a restart is required after granting permissions."
                    )
                }
            } else {
                Text("Select a topic")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Close")
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
