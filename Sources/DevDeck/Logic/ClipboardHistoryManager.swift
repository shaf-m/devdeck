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
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            // Ignore if it contains image data
            if let types = pasteboard.types, types.contains(.tiff) || types.contains(.png) {
                return
            }
            
            if let newString = pasteboard.string(forType: .string) {
                // Avoid duplicates at the top of the list
                if let first = history.first, first.text == newString {
                    return
                }
                
                let newItem = ClipboardItem(text: newString, timestamp: Date())
                
                DispatchQueue.main.async {
                    // Add to top, keep only last 6
                    self.history.insert(newItem, at: 0)
                    if self.history.count > 6 {
                        self.history.removeLast()
                    }
                }
            }
        }
    }
    
    func copy(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        // Update change count so we don't re-add it as a "new" item immediately if we don't want to involved logic for that
        // But actually, standard behavior is that if you copy from history, it becomes the "latest" again.
        // However, since we just inserted it at 0 if it's new, or if we are just pasting, we might want to rotate it to top.
        // For now, let's just let the monitor pick it up or manually move it.
        
        // Manually move to top to be instant
        moveToTop(item)
    }
    
    private func moveToTop(_ item: ClipboardItem) {
        if let index = history.firstIndex(of: item) {
            history.remove(at: index)
            history.insert(item, at: 0)
        }
    }
}
