import SwiftUI

struct RadialMenuView: View {
    @ObservedObject var profileManager: ProfileManager
    var onExecute: (Macro) -> Void
    
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    @State private var isVisible = false
    
    // Helper to get icon for current profile
    func getProfileIcon() -> NSImage? {
        if let bundleId = profileManager.activeProfile?.associatedBundleIds.first,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Circular Glass Background (The "Stage")
                Circle()
                    .fill(.ultraThinMaterial)
                    .background(Circle().fill(Color.black.opacity(0.6))) // Darker backing
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white.opacity(0.2), .white.opacity(0.05)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15) // Deep shadow
                    .padding(20)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.9)
                    .animation(.easeOut(duration: 0.25), value: isVisible)
                
                // 2. Central "Hub" (App Icon)
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                        .frame(width: 140, height: 140) // Larger Hub
                        .overlay(
                            Circle().stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        if let icon = getProfileIcon() {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64, height: 64)
                                .shadow(radius: 5)
                        } else {
                            // Fallback / Global Icon
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(profileManager.activeProfile?.name ?? "Global")
                            .font(.system(size: 14, weight: .bold, design: .monospaced)) // SF Mono
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(profileManager.activeProfile?.macros.count ?? 0) macros")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Circle())
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isVisible)
                .onTapGesture {
                    withAnimation {
                        profileManager.cycleNextProfile()
                    }
                }
                
                // 3. Action Nodes
                if let macros = profileManager.activeProfile?.macros {
                    ForEach(Array(macros.enumerated()), id: \.element.id) { index, macro in
                        RadialButton(macro: macro, index: index, total: macros.count, radius: 170) { // Increased radius
                            onExecute(macro)
                        }
                        .scaleEffect(isVisible ? 1 : 0.01)
                        .opacity(isVisible ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.03 + 0.15),
                            value: isVisible
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                withAnimation {
                    isVisible = true
                }
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Execution Failed"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
            .onReceive(NotificationCenter.default.publisher(for: .macroExecutionFailed)) { notification in
                if let error = notification.userInfo?["error"] as? String {
                    self.errorMessage = error
                    self.showError = true
                }
            }
        }
    }
}

struct RadialButton: View {
    let macro: Macro
    let index: Int
    let total: Int
    let radius: CGFloat
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        // Calculate angle: Start from -90 deg (Top)
        // Explicit breakdown for compiler speed
        let indexDouble = Double(index)
        let totalDouble = Double(total)
        let step = (360.0 / totalDouble)
        let angleDegrees = indexDouble * step - 90.0
        let angleRadians = angleDegrees * .pi / 180.0
        
        let x = CGFloat(cos(angleRadians)) * radius
        let y = CGFloat(sin(angleRadians)) * radius
        
        return Button(action: action) {
            buttonView
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: x, y: y)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var buttonView: some View {
        VStack(spacing: 8) {
            ZStack {
                // Node Circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(nsColor: .controlAccentColor).opacity(0.7),
                                Color.purple.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: isHovering ? Color(nsColor: .controlAccentColor).opacity(0.6) : .clear, radius: 15) // Glow on hover
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                
                Image(systemName: macro.iconName ?? "circle")
                    .font(.system(size: 22, weight: .semibold)) // slightly smaller execution
                    .foregroundColor(.white)
            }
            .scaleEffect(isHovering ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            
            // Label (Monospaced)
            Text(macro.label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.black.opacity(0.6)))
                .shadow(radius: 2)
        }
        // Badge Overlay
        .overlay(
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
            }
            .offset(x: 22, y: -22) // Adjusted offset
            , alignment: .top
        )
    }
}
