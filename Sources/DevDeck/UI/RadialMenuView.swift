import SwiftUI

struct RadialMenuView: View {
    @ObservedObject var profileManager: ProfileManager
    var onExecute: (Macro) -> Void
    
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    @State private var isVisible = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Circular Glass Background
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().fill(Color.black.opacity(0.4)))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(10) // Slight padding so shadow isn't clipped by window bounds? 
                                 // Actually window is 500x500, so we can fill it mostly.
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8) // Adding scale in for window entrance feel
                    .animation(.easeOut(duration: 0.2), value: isVisible)
                
                // Central "Hub"
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 4) {
                        Text(profileManager.activeProfile?.name ?? "None")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("\(profileManager.activeProfile?.macros.count ?? 0) macros")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("v2.0")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }
                .contentShape(Circle()) // Make the whole hub clickable
                .scaleEffect(isVisible ? 1 : 0.8)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.05), value: isVisible)
                .onTapGesture {
                    withAnimation {
                        profileManager.cycleNextProfile()
                    }
                }
                
                if let macros = profileManager.activeProfile?.macros {
                    ForEach(Array(macros.enumerated()), id: \.element.id) { index, macro in
                        RadialButton(macro: macro, index: index, total: macros.count, radius: 140) {
                            onExecute(macro)
                        }
                        .scaleEffect(isVisible ? 1 : 0.5)
                        .opacity(isVisible ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.03 + 0.1),
                            value: isVisible
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                isVisible = true
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
        let angle = Double(index) / Double(total) * 2 * .pi - .pi / 2
        let x = cos(angle) * Double(radius)
        let y = sin(angle) * Double(radius)
        
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: isHovering ? .white.opacity(0.5) : .clear, radius: 10)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    Image(systemName: macro.iconName ?? "circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHovering ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
                
                Text(macro.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
            .overlay(
                // Shortcut Badge
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(.white.opacity(0.9)))
                    .offset(x: 20, y: -20) // Top-right of icon
                , alignment: .top
            )
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: x, y: y)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
