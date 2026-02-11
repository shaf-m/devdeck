import SwiftUI

struct RadialMenuView: View {
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var clipboardManager: ClipboardHistoryManager
    var previewProfile: Profile? = nil // Optional preview override
    var onExecute: (Macro) -> Void
    var onPaste: ((ClipboardItem) -> Void)? = nil // NEW: Handle paste
    var onClose: (() -> Void)? = nil // Optional close handler
    var circlePadding: CGFloat = 20
    
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    @State private var isVisible = false
    @State private var menuMode: MenuMode = .main
    @Namespace private var namespace
    
    enum MenuMode {
        case main
        case history
    }
    
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
                    .background(Circle().fill(Color(NSColor.windowBackgroundColor).opacity(0.5))) // Adaptive backing
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.primary.opacity(0.1), .primary.opacity(0.05)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5) // Reduced shadow
                    .padding(circlePadding)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.9)
                    .animation(.easeOut(duration: 0.25), value: isVisible)
                
                // 2. Central "Hub" (App Icon)
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(Circle().fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
                        .frame(width: 140, height: 140) // Larger Hub
                        .overlay(
                            Circle().stroke(.primary.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        if menuMode == .main {
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
                                .foregroundColor(.primary.opacity(0.9))
                            
                            HStack(spacing: 4) {
                                Text("switch")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        } else {
                           // History Mode Icon
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("History")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary.opacity(0.9))
                        }
                    }
                }
                .contentShape(Circle())
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isVisible)
                .onTapGesture {
                    if menuMode == .main {
                        withAnimation {
                            profileManager.cycleNextProfile()
                        }
                    }
                }
                
                // 3. Switcher / Back Button in Center Hub area
                VStack {
                    Spacer()
                     if menuMode == .main {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                menuMode = .history
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.clipboard")
                                Text("History")
                            }
                            .font(.system(size: 12, design: .monospaced)) // SF Mono 12-14pt
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.ultraThinMaterial))
                            .overlay(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 0.5))
                            .shadow(radius: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 130) // Position it above the Close node (radius 170). Close Node center is ~170 from center, or ~80 from bottom in 500px view. 
                        // If view is centered, center is at 50% height. Close node is at center + 170.
                        // We want this button at roughly center + 120.
                        // Using Spacer + padding bottom means padding from bottom edge effectively if centered?
                        // Actually let's use offset in ZStack which is cleaner.
                        .matchedGeometryEffect(id: "historyPill", in: namespace)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxHeight: .infinity)
                // Wait, VStack with Spacer works relative to the container frame.
                // If container is infinite, Spacer pushes to bottom.
                // If I want it at center + 120, I should probably just position it in ZStack.
                
                // 4. Action Nodes + Close Button (Main Mode)
                if menuMode == .main {
                    if let macros = displayProfile?.macros {
                        let totalItems = macros.count + 1
                        let closeIndex = macros.count
                        
                        // Calculate step. Close button is at bottom (90 deg).
                        let step = 360.0 / Double(totalItems)
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
                
                // 5. History View (Circular Layout)
                if menuMode == .history {
                    let historyItems = clipboardManager.history
                    let totalItems = historyItems.count + 1
                    let backIndex = historyItems.count
                    
                    let step = 360.0 / Double(totalItems)
                    let rotationOffset = 180.0 - (Double(backIndex) * step) // Back button at bottom
                    
                    ForEach(0..<totalItems, id: \.self) { index in
                        if index < historyItems.count {
                            let item = historyItems[index]
                            
                             // We pass these purely for the Button view, but we can just use the view
                            ClipboardPillButton(
                                item: item,
                                index: index,
                                total: totalItems,
                                radius: 170,
                                rotationOffset: rotationOffset,
                                action: {
                                    // Paste action
                                    onPaste?(item)
                                    // UI Close is handled by onPaste usually or we can close here too
                                    onClose?()
                                }
                            )
                        } else {
                           // Back Button (replaces Close)
                           RadialNodeButton(
                                iconName: "chevron.left",
                                label: "Back",
                                index: index,
                                total: totalItems,
                                radius: 170,
                                rotationOffset: rotationOffset,
                                isCloseButton: true, // Reuse style
                                action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        menuMode = .main
                                    }
                                }
                            )
                        }
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
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

struct ClipboardPillButton: View {
    let item: ClipboardItem
    let index: Int
    let total: Int
    let radius: CGFloat
    let rotationOffset: Double
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        let indexDouble = Double(index)
        let totalDouble = Double(total)
        let step = (360.0 / totalDouble)
        let angleDegrees = indexDouble * step - 90.0 + rotationOffset
        let angleRadians = angleDegrees * .pi / 180.0
        
        let x = CGFloat(cos(angleRadians)) * radius
        let y = CGFloat(sin(angleRadians)) * radius
        
        return Button(action: action) {
             HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.text)
                        .lineLimit(1)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: 100, alignment: .leading)
                    
                    Text(item.timestamp, style: .time)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: isHovering ?
                                [Color(nsColor: .controlAccentColor).opacity(0.8), Color.purple.opacity(0.8)] :
                                [Color.black.opacity(0.6), Color.black.opacity(0.4)]
                            ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isHovering ? 0.5 : 0.2), lineWidth: 1)
            )
            .shadow(color: isHovering ? Color.purple.opacity(0.5) : .clear, radius: 10)
            .scaleEffect(isHovering ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: x, y: y)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
