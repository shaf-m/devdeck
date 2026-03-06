import SwiftUI
import Combine

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let timestamp: Date
}

class ClipboardHistoryManager: ObservableObject {
    @Published var history: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0

    /// Driven by AppStorage in the UI; read directly here via UserDefaults.
    private var limit: Int {
        UserDefaults.standard.integer(forKey: "historyLimit").nonZero(default: 10)
    }

    init() {
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Ignore image data
        if let types = pasteboard.types, types.contains(.tiff) || types.contains(.png) { return }

        guard let newString = pasteboard.string(forType: .string) else { return }

        // Avoid duplicate at top
        if let first = history.first, first.text == newString { return }

        let newItem = ClipboardItem(text: newString, timestamp: Date())
        DispatchQueue.main.async {
            self.history.insert(newItem, at: 0)
            // Trim to current limit
            if self.history.count > self.limit {
                self.history = Array(self.history.prefix(self.limit))
            }
        }
    }

    func copy(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        moveToTop(item)
    }

    /// Remove all entries from the in-memory history list.
    func clearAll() {
        withAnimation(.easeOut(duration: 0.25)) {
            history.removeAll()
        }
    }

    private func moveToTop(_ item: ClipboardItem) {
        if let index = history.firstIndex(of: item) {
            history.remove(at: index)
            history.insert(item, at: 0)
        }
    }
}

// MARK: - Helpers

private extension Int {
    /// Returns self if non-zero, otherwise returns the given default.
    func nonZero(default fallback: Int) -> Int { self == 0 ? fallback : self }
}
