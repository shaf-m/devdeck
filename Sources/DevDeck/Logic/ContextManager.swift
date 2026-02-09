import Cocoa
import Combine

class ContextManager: ObservableObject {
    @Published var activeContext: String = "Global"
    @Published var activeBundleId: String = ""
    @Published var lastActiveApp: NSRunningApplication?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Mapping from Bundle ID to Profile Name
    private let bundleIdScan: [String: String] = [
        "com.microsoft.VSCode": "VS Code",
        "com.google.Chrome": "Browser",
        "com.apple.Safari": "Browser",
        "com.apple.Terminal": "Terminal",
        "com.googlecode.iterm2": "Terminal",
        "com.jetbrains.intellij": "IntelliJ"
    ]
    
    init() {
        setupObservation()
        // Initial check
        if let currentApp = NSWorkspace.shared.frontmostApplication {
            updateContext(for: currentApp)
        }
    }
    
    private func setupObservation() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .sink { [weak self] app in
                // Start tracking immediately
                self?.updateContext(for: app)
            }
            .store(in: &cancellables)
    }
    
    private func updateContext(for app: NSRunningApplication) {
        // Ignore our own app activating (if we ever accidentally do)
        if app.bundleIdentifier == Bundle.main.bundleIdentifier { return }
        
        let bundleId = app.bundleIdentifier ?? ""
        DispatchQueue.main.async {
            self.lastActiveApp = app
            self.activeBundleId = bundleId
            if let profile = self.bundleIdScan[bundleId] {
                self.activeContext = profile
            } else {
                self.activeContext = "Global"
            }
            // print("Context changed to: \(self.activeContext) (\(bundleId))")
        }
    }
}
