import SwiftUI

// MARK: - Palette & icon data

private let colorSwatches: [(label: String, hex: String)] = [
    ("Red",       "#FF4444"),
    ("Orange",    "#FF8C00"),
    ("Amber",     "#FFB700"),
    ("Green",     "#34C759"),
    ("Teal",      "#00BCD4"),
    ("Blue",      "#007AFF"),
    ("Indigo",    "#5856D6"),
    ("Purple",    "#AF52DE"),
    ("Pink",      "#FF2D55"),
    ("Gray",      "#8E8E93"),
]

private let iconCategories: [(name: String, icons: [String])] = [
    ("General", [
        "bolt.fill", "star.fill", "heart.fill", "flag.fill", "tag.fill",
        "bookmark.fill", "bell.fill", "exclamationmark.circle.fill",
        "checkmark.circle.fill", "xmark.circle.fill", "plus.circle.fill",
        "minus.circle.fill", "arrow.right.circle.fill", "lightbulb.fill",
        "flame.fill", "sparkles", "wand.and.stars", "crown.fill",
    ]),
    ("Dev", [
        "terminal.fill", "command", "keyboard", "curlybraces",
        "chevron.left.forwardslash.chevron.right", "cpu.fill",
        "memorychip.fill", "externaldrive.fill", "internaldrive.fill",
        "network", "wifi", "antenna.radiowaves.left.and.right",
        "globe", "globe.americas.fill", "server.rack",
        "doc.text.fill", "list.bullet.clipboard.fill", "function",
    ]),
    ("Actions", [
        "play.fill", "stop.fill", "pause.fill", "record.circle",
        "forward.fill", "backward.fill", "shuffle", "repeat",
        "arrow.clockwise", "arrow.counterclockwise",
        "arrow.up.circle.fill", "arrow.down.circle.fill",
        "square.and.arrow.up.fill", "square.and.arrow.down.fill",
        "paperplane.fill", "tray.full.fill", "envelope.fill",
        "link", "scissors", "doc.on.clipboard",
    ]),
    ("Files", [
        "folder.fill", "folder.badge.plus", "doc.fill",
        "doc.text.fill", "doc.richtext.fill", "photo.fill",
        "camera.fill", "video.fill", "music.note", "waveform",
        "archivebox.fill", "trash.fill", "externaldrive.badge.plus",
        "icloud.fill", "icloud.and.arrow.up.fill",
    ]),
    ("Apps & UI", [
        "safari.fill", "gear", "gearshape.fill", "gearshape.2.fill",
        "slider.horizontal.3", "circle.grid.2x2.fill",
        "rectangle.grid.2x2.fill", "square.stack.3d.up.fill",
        "macwindow", "uiwindow.split.2x1",
        "menubar.rectangle", "desktopcomputer",
        "laptopcomputer", "iphone", "applewatch",
        "paintpalette.fill", "eyedropper.halffull",
    ]),
]

// MARK: - MacroConfigCard

struct MacroConfigCard: View {
    @Binding var macro: Macro

    var onDelete: () -> Void
    var onEdit: (() -> Void)? = nil
    var isNew: Bool = false
    var onInteract: (() -> Void)? = nil

    @State private var showIconPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Icon & Label
            HStack(spacing: 12) {
                // Drag Handle
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 20))
                    .onTapGesture { onInteract?() }
                    .onChange(of: macro) { _ in onEdit?() }
                    .frame(width: 24)
                    .accessibilityLabel("Drag to Reorder")

                // Icon + colour button — opens picker sheet
                Button { showIconPicker = true } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: tileColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: macro.iconName ?? "bolt.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Choose icon & colour")
                .sheet(isPresented: $showIconPicker) {
                    IconColorPickerSheet(
                        selectedIcon: Binding(
                            get: { macro.iconName ?? "bolt.fill" },
                            set: { macro.iconName = $0 }
                        ),
                        selectedColorHex: Binding(
                            get: { macro.iconColor },
                            set: { macro.iconColor = $0 }
                        )
                    )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Label")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Macro Name", text: $macro.label)
                        .textFieldStyle(.plain)
                        .font(.headline)
                }

                if isDefaultMacro {
                    Text("NEW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .help("This is a new macro with default values")
                }

                Spacer()

                // Delete Button
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.6))
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())
                .help("Delete Macro")
            }
            .padding(.bottom, 4)

            Divider()
                .background(Color.secondary.opacity(0.2))

            // Action Type & Value
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Action Type")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("Action", selection: $macro.type) {
                        Text("Shell Script").tag(MacroType.shellScript)
                        Text("AppleScript").tag(MacroType.appleScript)
                        Text("Key Shortcut").tag(MacroType.keystroke)
                        Text("URL").tag(MacroType.url)
                        Text("Text/Paste").tag(MacroType.text)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: 120)
                }

                Group {
                    if macro.type == .shellScript || macro.type == .appleScript {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Script")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $macro.value)
                                .font(.system(.caption, design: .monospaced))
                                .frame(height: 70)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                    } else if macro.type == .keystroke {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shortcut")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ShortcutRecorder(shortcutValue: $macro.value)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField(placeholderForType(macro.type), text: $macro.value)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(height: 240)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)

                if isNew || isDefaultMacro {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                }
            }
        )
    }

    // MARK: - Helpers

    private var tileColors: [Color] {
        if let hex = macro.iconColor, let base = Color(hex: hex) {
            return [base.opacity(0.85), base.opacity(0.6)]
        }
        return [Color.blue.opacity(0.7), Color.purple.opacity(0.6)]
    }

    private func placeholderForType(_ type: MacroType) -> String {
        switch type {
        case .shellScript, .appleScript: return "Script..."
        case .keystroke: return "e.g. ⌘C"
        case .url: return "https://example.com"
        case .text: return "Text to paste..."
        }
    }

    private var isDefaultMacro: Bool {
        macro.label == "New Macro" &&
        macro.value == "echo 'Hello World'" &&
        macro.type == .shellScript
    }
}

// MARK: - Icon & Colour Picker Sheet

struct IconColorPickerSheet: View {
    @Binding var selectedIcon: String
    @Binding var selectedColorHex: String?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Sheet header
            HStack {
                Text("Icon & Colour")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Colour swatches ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Colour", systemImage: "paintpalette.fill")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 8) {
                            // Default swatch (accent gradient)
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                if selectedColorHex == nil {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .onTapGesture { selectedColorHex = nil }

                            ForEach(colorSwatches, id: \.hex) { swatch in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: swatch.hex) ?? .gray)
                                        .frame(width: 32, height: 32)
                                    if selectedColorHex == swatch.hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .help(swatch.label)
                                .onTapGesture { selectedColorHex = swatch.hex }
                            }
                        }
                    }

                    Divider()

                    // ── Icon search ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Icon", systemImage: "square.grid.2x2.fill")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search icons…", text: $searchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                    }

                    // ── Icon grid by category ─────────────────────────────
                    let allIcons = iconCategories.flatMap(\.icons)
                    let filteredAll = searchText.isEmpty ? nil : allIcons.filter { $0.localizedCaseInsensitiveContains(searchText) }

                    if let filtered = filteredAll {
                        iconGrid(icons: filtered, label: "Results")
                    } else {
                        ForEach(iconCategories, id: \.name) { cat in
                            iconGrid(icons: cat.icons, label: cat.name)
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 520)
    }

    @ViewBuilder
    private func iconGrid(icons: [String], label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 6) {
                ForEach(icons, id: \.self) { icon in
                    let isSelected = selectedIcon == icon
                    let tileColor: Color = {
                        if let hex = selectedColorHex, let c = Color(hex: hex) { return c }
                        return Color.blue
                    }()
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected
                                  ? LinearGradient(colors: [tileColor.opacity(0.85), tileColor.opacity(0.55)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                  : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 38, height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? .white : .primary.opacity(0.7))
                    }
                    .help(icon)
                    .onTapGesture { selectedIcon = icon }
                }
            }
        }
    }
}
