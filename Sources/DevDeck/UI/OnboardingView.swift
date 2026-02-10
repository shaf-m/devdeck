import SwiftUI
import ApplicationServices

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    // Check for accessibility permissions
    @State private var isAccessibilityTrusted = AXIsProcessTrusted()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer()
                
                Group {
                    switch currentPage {
                    case 0:
                        WelcomePage()
                    case 1:
                        ConceptPage(
                            title: "The Overlay",
                            description: "Hold the tilde ~ key to peek at your shortcuts. Use the radial menu for quick access.",
                            imageName: "circle.circle",
                            color: .blue
                        )
                    case 2:
                        ConceptPage(
                            title: "Profiles",
                            description: "DevDeck automatically switches profiles based on the active application. VS Code shortcuts when you code, Safari shortcuts when you browse.",
                            imageName: "folder.fill",
                            color: .orange
                        )
                    case 3:
                        PermissionsPage(isTrusted: $isAccessibilityTrusted)
                    case 4:
                        CompletionPage(onFinish: {
                            isPresented = false
                        })
                    default:
                        EmptyView()
                    }
                }
                .transition(.push(from: .trailing))
                
                Spacer()
                
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
                
                // Navigation Controls
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .keyboardShortcut(.cancelAction)
                    } else {
                        Spacer().frame(width: 60) // Placeholder to keep layout balanced
                    }
                    
                    Spacer()
                    
                    if currentPage < 4 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.defaultAction)
                        .disabled(currentPage == 3 && !isAccessibilityTrusted)
                        .opacity(currentPage == 3 && !isAccessibilityTrusted ? 0.5 : 1)
                    } else {
                        Spacer().frame(width: 80) // Placeholder
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .frame(width: 700, height: 600)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Close Button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(20)
        }
    }
}


// MARK: - Pages

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("<DevDeck>")
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("The ultimate macro manager for developers.")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Streamline your workflow with context-aware shortcuts and a powerful radial menu.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ConceptPage: View {
    let title: String
    let description: String
    let imageName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 32, weight: .bold))
            
            Text(description)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct PermissionsPage: View {
    @Binding var isTrusted: Bool
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(isTrusted ? .green : .red)
            
            Text("Permissions Required")
                .font(.system(size: 32, weight: .bold))
            
            VStack(spacing: 20) {
                Text("DevDeck needs Accessibility permissions to detect focused apps and inject keystrokes.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if isTrusted {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("Access Granted")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    Button(action: {
                        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                        AXIsProcessTrustedWithOptions(options)
                    }) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("Grant Access")
                        }
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    
                    Text("System Settings > Privacy & Security > Accessibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .onReceive(timer) { _ in
            isTrusted = AXIsProcessTrusted()
        }
    }
}

struct CompletionPage: View {
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("All Set!")
                .font(.system(size: 36, weight: .bold))
            
            Text("You are ready to use DevDeck. \nPress the Help button in the dashboard anytime to review tutorials.")
                .multilineTextAlignment(.center)
                .font(.title2)
                .foregroundColor(.secondary)
            
            Button(action: {
                onFinish()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}
