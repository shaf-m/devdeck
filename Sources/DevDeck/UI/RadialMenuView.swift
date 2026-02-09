import SwiftUI

struct RadialMenuView: View {
    @ObservedObject var profileManager: ProfileManager
    var previewProfile: Profile? = nil // Optional preview override
    var onExecute: (Macro) -> Void
    var onClose: (() -> Void)? = nil // Optional close handler
    var circlePadding: CGFloat = 20
    
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    @State private var isVisible = false
    
    // Helper to resolve which profile to show
    private var displayProfile: Profile? {
        previewProfile ?? profileManager.activeProfile
    }
    
    // Helper to get icon for current profile
    func getProfileIcon() -> NSImage? {
        if let bundleId = displayProfile?.associatedBundleIds.first,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 0. Background Tap to Close
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onClose?()
                    }
                
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
                    .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 5) // Reduced shadow to fit 500x500
                    .padding(circlePadding)
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
                        
                        Text(displayProfile?.name ?? "Global")
                            .font(.system(size: 14, weight: .bold, design: .monospaced)) // SF Mono
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 4) {
                            Text("switch")
                            Image(systemName: "chevron.right")
                        }
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
                
                // 3. Action Nodes + Close Button
                // We treat the Close button as the (N+1)th item.
                // We rotate the entire setup so the Close button (last item) is at 90 deg (Bottom).
                if let macros = displayProfile?.macros {
                    let totalItems = macros.count + 1
                    let closeIndex = macros.count
                    
                    // Calculate step angle
                    let step = 360.0 / Double(totalItems)
                    
                    // Goal: Last item (closeIndex) should be at 90 degrees.
                    // Normal Angle = index * step - 90.
                    // Target Angle = 90.
                    // Equation: (closeIndex * step - 90) + offset = 90
                    // offset = 180 - (closeIndex * step)
                    let rotationOffset = 180.0 - (Double(closeIndex) * step)
                    
                    ForEach(0..<totalItems, id: \.self) { index in
                        if index < macros.count {
                            // Macro Node
                            let macro = macros[index]
                            RadialNodeButton(
                                iconName: macro.iconName ?? "circle",
                                label: macro.label,
                                index: index,
                                total: totalItems,
                                radius: 170,
                                rotationOffset: rotationOffset,
                                isCloseButton: false,
                                action: { onExecute(macro) }
                            )
                        } else {
                            // Close Button Node
                            RadialNodeButton(
                                iconName: "xmark",
                                label: "Close",
                                index: index,
                                total: totalItems,
                                radius: 170,
                                rotationOffset: rotationOffset,
                                isCloseButton: true,
                                action: { onClose?() }
                            )
                        }
                    }
                    .scaleEffect(isVisible ? 1 : 0.01)
                    .opacity(isVisible ? 1 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(0.15),
                        value: isVisible
                    )
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
        .background(Color.clear)
    }
}

struct RadialNodeButton: View {
    let iconName: String
    let label: String
    let index: Int
    let total: Int
    let radius: CGFloat
    let rotationOffset: Double
    let isCloseButton: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        // Calculate angle: Start from -90 deg (Top)
        // Apply rotationOffset to shift the whole ring
        let indexDouble = Double(index)
        let totalDouble = Double(total)
        let step = (360.0 / totalDouble)
        let angleDegrees = indexDouble * step - 90.0 + rotationOffset
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
                            gradient: Gradient(colors: isCloseButton ?
                                [Color.gray.opacity(0.4), Color.black.opacity(0.6)] :
                                [Color(nsColor: .controlAccentColor).opacity(0.7), Color.purple.opacity(0.7)]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(isCloseButton ? .white.opacity(0.2) : .white.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: isHovering ? (isCloseButton ? .white.opacity(0.2) : Color(nsColor: .controlAccentColor).opacity(0.6)) : .clear, radius: 15) // Glow on hover
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .semibold)) // slightly smaller execution
                    .foregroundColor(.white)
            }
            .scaleEffect(isHovering ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            
            // Label (Monospaced)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.black.opacity(0.6)))
                .shadow(radius: 2)
        }
        // Badge Overlay (Only for Macros)
        .overlay(
            Group {
                if !isCloseButton {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                    }
                    .offset(x: 22, y: -22)
                }
            }
            , alignment: .top
        )
    }
}
