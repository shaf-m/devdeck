import SwiftUI
import AppKit

struct CodeEditorView: View {
    @Binding var text: String
    var language: String
    var isEditable: Bool = true

    @State private var lineCount: Int = 1
    @State private var charCount: Int = 0
    @State private var copied: Bool = false

    // Monospaced line height – approximate, matches the TextEditor's font size
    private let lineHeight: CGFloat = 21

    var body: some View {
        VStack(spacing: 0) {
            // ── Editor Area ───────────────────────────────────────────────
            HStack(spacing: 0) {

                // Line Numbers Gutter
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(1...max(lineCount, 1), id: \.self) { n in
                            Text("\(n)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.5))
                                .frame(height: lineHeight, alignment: .top)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 9)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 8)
                }
                // Fixed gutter width – grows with digit count
                .frame(width: lineCountWidth())
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Main Editor / Viewer
                ZStack(alignment: .topTrailing) {
                    if isEditable {
                        TextEditor(text: $text)
                            .font(.system(size: 13, design: .monospaced))
                            .lineSpacing(4)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.textBackgroundColor))
                            .onChange(of: text) { newValue in
                                updateCounts(newValue)
                            }
                    } else {
                        ScrollView {
                            Text(text)
                                .font(.system(size: 13, design: .monospaced))
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .textSelection(.enabled)
                        }
                        .background(Color(NSColor.textBackgroundColor))
                    }

                    // Copy Button (top-right)
                    Button(action: copyAndAnimate) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(copied ? .green : .secondary)
                            .padding(6)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.85))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        copied
                                            ? Color.green.opacity(0.5)
                                            : Color.secondary.opacity(0.2),
                                        lineWidth: 0.5
                                    )
                            )
                            .animation(.easeInOut(duration: 0.15), value: copied)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .help(copied ? "Copied!" : "Copy to Clipboard")
                }
            }

            // ── Status Bar ─────────────────────────────────────────────────
            Divider()
            HStack(spacing: 12) {
                Label("\(lineCount) \(lineCount == 1 ? "line" : "lines")", systemImage: "list.bullet")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Divider().frame(height: 12)

                Label("\(charCount) \(charCount == 1 ? "char" : "chars")", systemImage: "character.cursor.ibeam")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Text(languageDisplayName(language))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            updateCounts(text)
        }
    }

    // MARK: - Helpers

    private func updateCounts(_ value: String) {
        let lines = value.components(separatedBy: .newlines)
        lineCount = lines.count
        charCount = value.count
    }

    private func copyAndAnimate() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { copied = false }
        }
    }

    /// Gutter width scales with the number of digits in the line count.
    private func lineCountWidth() -> CGFloat {
        let digits = max(2, String(lineCount).count)
        return CGFloat(digits) * 9 + 24
    }

    private func languageDisplayName(_ code: String) -> String {
        switch code {
        case "sh":          return "Shell Script"
        case "py":          return "Python"
        case "js":          return "JavaScript"
        case "ts":          return "TypeScript"
        case "java":        return "Java"
        case "c":           return "C"
        case "sql":         return "SQL"
        case "html":        return "HTML"
        case "css":         return "CSS"
        case "json":        return "JSON"
        case "yaml":        return "YAML"
        case "applescript": return "AppleScript"
        case "txt":         return "Plain Text"
        default:            return code
        }
    }
}
