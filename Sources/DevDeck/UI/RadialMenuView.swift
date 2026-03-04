import SwiftUI

// MARK: - DeckMacroCard

struct DeckMacroCard: View {
    let macro: Macro
    let index: Int
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack(alignment: .topTrailing) {
                    // Icon tile
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(nsColor: .controlAccentColor).opacity(0.75),
                                        Color.purple.opacity(0.65)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)
                            .shadow(
                                color: isHovering
                                    ? Color(nsColor: .controlAccentColor).opacity(0.55)
                                    : .clear,
                                radius: 10
                            )

                        Image(systemName: macro.iconName ?? "bolt.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white.opacity(isHovering ? 0.4 : 0.15), lineWidth: 0.8)
                    )

                    // Numbered badge
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 17, height: 17)
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                    }
                    .offset(x: 6, y: -6)
                }

                // Label
                Text(macro.label)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineLimit(1)
                    .frame(maxWidth: 80)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovering ? Color.white.opacity(0.08) : Color.clear)
            )
            .scaleEffect(isPressed ? 0.91 : (isHovering ? 1.04 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - DeckClipboardRow

struct DeckClipboardRow: View {
    let item: ClipboardItem
    let index: Int
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Accent stripe on hover
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        isHovering
                        ? LinearGradient(
                            colors: [Color(nsColor: .controlAccentColor), .purple],
                            startPoint: .top, endPoint: .bottom
                          )
                        : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 3)
                    .padding(.vertical, 6)

                HStack(spacing: 10) {
                    // Index badge
                    ZStack {
                        Circle()
                            .fill(isHovering ? Color(nsColor: .controlAccentColor).opacity(0.2) : Color.white.opacity(0.08))
                            .frame(width: 20, height: 20)
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(isHovering ? Color(nsColor: .controlAccentColor) : .secondary)
                    }

                    // Clipboard icon
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isHovering ? Color(nsColor: .controlAccentColor) : .secondary.opacity(0.6))
                        .frame(width: 14)

                    // Text preview
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary.opacity(isHovering ? 1.0 : 0.8))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(item.timestamp, style: .relative)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.6))
                    }

                    Spacer(minLength: 4)
                }
                .padding(.leading, 10)
                .padding(.trailing, 12)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isHovering
                        ? Color(nsColor: .controlAccentColor).opacity(0.07)
                        : Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isHovering ? Color(nsColor: .controlAccentColor).opacity(0.18) : Color.clear,
                        lineWidth: 0.6
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovering = hovering }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = false }
                }
        )
    }
}


// MARK: - RadialMenuView (Deck Panel)

struct RadialMenuView: View {
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var clipboardManager: ClipboardHistoryManager
    var previewProfile: Profile? = nil
    var onExecute: (Macro) -> Void
    var onPaste: ((ClipboardItem) -> Void)? = nil
    var onClose: (() -> Void)? = nil
    var onOpenDashboard: (() -> Void)? = nil
    // Legacy parameter kept for compatibility, unused in new layout
    var circlePadding: CGFloat = 20
    var showHistory: Bool = true

    @State private var isVisible = false
    @State private var menuMode: MenuMode = .main
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var showCopiedToast = false

    enum MenuMode {
        case main
        case history
    }

    private var displayProfile: Profile? {
        previewProfile ?? profileManager.activeProfile
    }

    func getProfileIcon() -> NSImage? {
        if let bundleId = displayProfile?.associatedBundleIds.first,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    // MARK: Gradient border stops
    private var borderGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(nsColor: .controlAccentColor).opacity(0.7), location: 0),
                .init(color: Color.purple.opacity(0.5), location: 0.5),
                .init(color: Color.white.opacity(0.05), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Body
    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider()
                .opacity(0.15)

            if menuMode == .history {
                historyContent
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        )
                    )
            } else {
                macroGrid
                    .transition(.opacity)
            }

            Divider()
                .opacity(0.15)

            footerBar
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .frame(width: 370)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.35))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderGradient, lineWidth: 1.0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        // System window shadow (hasShadow=true on NSPanel) handles the drop shadow
        // without clipping — no SwiftUI .shadow() needed here.
        // Copied-to-clipboard toast overlay
        .overlay(
            ZStack {
                if showCopiedToast {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(nsColor: .controlAccentColor).opacity(0.2), Color.purple.opacity(0.15)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Image(systemName: "checkmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(nsColor: .controlAccentColor), .purple],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                        }
                        Text("Copied to clipboard")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.85))
                    }
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCopiedToast)
            .allowsHitTesting(false)
        )
        .scaleEffect(isVisible ? 1 : 0.95)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isVisible)
        .onAppear {
            withAnimation { isVisible = true }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Execution Failed"),
                message: Text(errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .macroExecutionFailed)) { notification in
            if let error = notification.userInfo?["error"] as? String {
                errorMessage = error
                showError = true
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 10) {
            // Profile icon (no background tile — icon slightly larger)
            Group {
                if let icon = getProfileIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(nsColor: .controlAccentColor),
                                    Color.purple
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .frame(width: 36, height: 36)

            // Profile name + macro count
            VStack(alignment: .leading, spacing: 2) {
                Text(displayProfile?.name ?? "Global")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                let macroCount = displayProfile?.macros.count ?? 0
                Text("\(macroCount) macro\(macroCount == 1 ? "" : "s")")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Cycle button (only in main mode)
            if menuMode == .main {
                HeaderIconButton(systemName: "arrow.2.circlepath") {
                    withAnimation(.spring()) {
                        profileManager.cycleNextProfile()
                    }
                }
            }

            // Back button (only in history mode)
            if menuMode == .history {
                HeaderIconButton(systemName: "chevron.left") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        menuMode = .main
                    }
                }
            }

            // Close button (always)
            HeaderIconButton(systemName: "xmark") {
                onClose?()
            }
        }
    }

    // MARK: - Macro Grid

    private var macroGrid: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        return Group {
            if let macros = displayProfile?.macros, !macros.isEmpty {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(macros.enumerated()), id: \.element.id) { index, macro in
                        DeckMacroCard(macro: macro, index: index) {
                            onExecute(macro)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No macros in this profile")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
    }

    // MARK: - History Content

    private var historyContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 2) {
                if clipboardManager.history.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No clipboard history")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    ForEach(Array(clipboardManager.history.enumerated()), id: \.element.id) { index, item in
                        DeckClipboardRow(item: item, index: index) {
                            onPaste?(item)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCopiedToast = true
                            }
                            // Fade the toast out after 2s — panel stays open
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.35)) {
                                    showCopiedToast = false
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
        }
        .frame(maxHeight: 280)
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack {
            // History capsule button
            if showHistory {
                HistoryFooterButton(isActive: menuMode == .history) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        menuMode = menuMode == .history ? .main : .history
                    }
                }
            }

            Spacer()

            // <DevDeck> button
            DevDeckFooterButton {
                onOpenDashboard?()
            }
        }
    }
}

// MARK: - Helper: HeaderIconButton

private struct HeaderIconButton: View {
    let systemName: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isHovering ? .primary : .secondary)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(isHovering ? Color.white.opacity(0.12) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

// MARK: - Helper: HistoryFooterButton

private struct HistoryFooterButton: View {
    let isActive: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 11))
                Text("History")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(isActive || isHovering ? .white : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        isActive || isHovering
                        ? LinearGradient(
                            colors: [
                                Color(nsColor: .controlAccentColor).opacity(0.8),
                                Color.purple.opacity(0.75)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isActive || isHovering
                        ? Color.white.opacity(0.3)
                        : Color.primary.opacity(0.15),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: isActive || isHovering ? Color.purple.opacity(0.4) : .clear,
                radius: 6
            )
            .scaleEffect(isHovering ? 1.04 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}

// MARK: - Helper: DevDeckFooterButton

private struct DevDeckFooterButton: View {
    let action: () -> Void
    @State private var isHovering = false

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(nsColor: .controlAccentColor), Color.purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        Button(action: action) {
            Text("<DevDeck>")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                // gradient text on hover, muted secondary at rest
                .foregroundStyle(
                    isHovering
                    ? AnyShapeStyle(accentGradient)
                    : AnyShapeStyle(Color.secondary.opacity(0.7))
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)   // matches HistoryFooterButton vertical padding
                .background(
                    Capsule()
                        .fill(isHovering ? Color.white.opacity(0.09) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isHovering
                            ? AnyShapeStyle(accentGradient.opacity(0.5))
                            : AnyShapeStyle(Color.primary.opacity(0.12)),
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}
