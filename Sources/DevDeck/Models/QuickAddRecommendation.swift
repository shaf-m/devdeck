import Foundation

enum QuickAddCategory: String, CaseIterable {
    case system = "System"
    case window = "Window Mgmt"
    case coding = "Git"
    case productivity = "Productivity"
    case microsoftTeams = "Microsoft Teams"
    case intellij = "IntelliJ"
    case pycharm = "PyCharm"
    case vscode = "VS Code"
}

struct QuickAddRecommendation: Identifiable {
    let id = UUID()
    let category: QuickAddCategory
    let label: String
    let iconName: String
    let type: MacroType
    let value: String
    
    // Pre-defined library
    static let all: [QuickAddRecommendation] = [
        // System
        .init(category: .system, label: "Lock Screen", iconName: "lock.fill", type: .keystroke, value: "cmd+ctrl+q"),
        .init(category: .system, label: "Sleep", iconName: "powersleep", type: .shellScript, value: "pmset sleepnow"),
        .init(category: .system, label: "Mute Audio", iconName: "speaker.slash.fill", type: .appleScript, value: "set volume output muted (not (output muted of (get volume settings)))"),
        .init(category: .system, label: "Screenshot", iconName: "camera.viewfinder", type: .keystroke, value: "cmd+shift+5"),
        .init(category: .system, label: "Empty Trash", iconName: "trash.fill", type: .appleScript, value: "tell application \"Finder\" to empty trash"),

        // Window Management
        .init(category: .window, label: "Split Left", iconName: "rectangle.leadingthird.inset.filled", type: .keystroke, value: "ctrl+opt+left"),
        .init(category: .window, label: "Split Right", iconName: "rectangle.trailingthird.inset.filled", type: .keystroke, value: "ctrl+opt+right"),
        .init(category: .window, label: "Maximize", iconName: "rectangle.inset.filled", type: .keystroke, value: "ctrl+opt+enter"),
        .init(category: .window, label: "Minimize", iconName: "minus.rectangle.fill", type: .keystroke, value: "cmd+m"),
        
        // Coding
        .init(category: .coding, label: "Git Status", iconName: "terminal", type: .text, value: "git status"),
        .init(category: .coding, label: "Git Push", iconName: "arrow.up.circle", type: .text, value: "git push"),
        .init(category: .coding, label: "Git Pull", iconName: "arrow.down.circle", type: .text, value: "git pull"),
        .init(category: .coding, label: "Clear Terminal", iconName: "xmark.bin", type: .keystroke, value: "cmd+k"),
        .init(category: .coding, label: "Copy Line", iconName: "doc.on.doc", type: .keystroke, value: "cmd+c"),
        
        // Productivity
        .init(category: .productivity, label: "Slack Away", iconName: "message.fill", type: .url, value: "slack://user?team=T12345&id=U12345"), 
        .init(category: .productivity, label: "Open Calendar", iconName: "calendar", type: .appleScript, value: "tell application \"Calendar\" to activate"),
        .init(category: .productivity, label: "New Email", iconName: "envelope.fill", type: .url, value: "mailto:"),
                
        // IntelliJ
        .init(category: .intellij, label: "Find Action", iconName: "magnifyingglass", type: .keystroke, value: "cmd+shift+a"),
        .init(category: .intellij, label: "Project View", iconName: "sidebar.left", type: .keystroke, value: "cmd+1"),
        .init(category: .intellij, label: "Run", iconName: "play.fill", type: .keystroke, value: "ctrl+r"),
        .init(category: .intellij, label: "Debug", iconName: "ladybug.fill", type: .keystroke, value: "ctrl+d"),
        .init(category: .intellij, label: "Stop", iconName: "stop.fill", type: .keystroke, value: "cmd+f2"),
        .init(category: .intellij, label: "Refactor", iconName: "hammer.fill", type: .keystroke, value: "ctrl+t"),

        // PyCharm
        .init(category: .pycharm, label: "Search Everywhere", iconName: "magnifyingglass.circle", type: .keystroke, value: "shift+shift"), 
        .init(category: .pycharm, label: "Find Action", iconName: "magnifyingglass", type: .keystroke, value: "cmd+shift+a"),
        .init(category: .pycharm, label: "Recent Files", iconName: "clock", type: .keystroke, value: "cmd+e"),
        .init(category: .pycharm, label: "Go to File", iconName: "doc.text.magnifyingglass", type: .keystroke, value: "cmd+shift+o"),
        .init(category: .pycharm, label: "Run", iconName: "play.fill", type: .keystroke, value: "ctrl+r"),

        // VS Code
        .init(category: .vscode, label: "Command Palette", iconName: "terminal.fill", type: .keystroke, value: "cmd+shift+p"),
        .init(category: .vscode, label: "Quick Open", iconName: "doc.text", type: .keystroke, value: "cmd+p"),
        .init(category: .vscode, label: "Toggle Sidebar", iconName: "sidebar.left", type: .keystroke, value: "cmd+b"),
        .init(category: .vscode, label: "Terminal", iconName: "chevron.right.square.fill", type: .keystroke, value: "ctrl+`"),
        .init(category: .vscode, label: "Split Editor", iconName: "square.split.2x1", type: .keystroke, value: "cmd+\\"),
        
        // Microsoft Teams
        .init(category: .microsoftTeams, label: "Mute/Unmute", iconName: "mic.slash.fill", type: .keystroke, value: "cmd+shift+m"),
        .init(category: .microsoftTeams, label: "Toggle Video", iconName: "video.fill", type: .keystroke, value: "cmd+shift+o"),
        .init(category: .microsoftTeams, label: "Raise Hand", iconName: "hand.raised.fill", type: .keystroke, value: "cmd+shift+k"),
        .init(category: .microsoftTeams, label: "Teams Search", iconName: "magnifyingglass", type: .keystroke, value: "cmd+e"),

        // VS Code (Additional)
        .init(category: .vscode, label: "Format Document", iconName: "doc.plaintext.fill", type: .keystroke, value: "shift+opt+f"),
        .init(category: .vscode, label: "Multi-Cursor", iconName: "cursorarrow.and.square.on.square.dashed", type: .keystroke, value: "opt+cmd+down"),
        .init(category: .vscode, label: "Comment Line", iconName: "text.quote", type: .keystroke, value: "cmd+/"),
        .init(category: .vscode, label: "Go to Symbol", iconName: "at", type: .keystroke, value: "cmd+shift+o"),
        .init(category: .vscode, label: "Explorer View", iconName: "folder.fill", type: .keystroke, value: "cmd+shift+e"),

        // IntelliJ (Additional)
        .init(category: .intellij, label: "Optimize Imports", iconName: "tray.and.arrow.down.fill", type: .keystroke, value: "ctrl+opt+o"),
        .init(category: .intellij, label: "Reformat Code", iconName: "text.alignleft", type: .keystroke, value: "opt+cmd+l"),
        .init(category: .intellij, label: "Generate Code", iconName: "plus.square.fill", type: .keystroke, value: "cmd+n"),
        .init(category: .intellij, label: "Quick Fix", iconName: "lightbulb.fill", type: .keystroke, value: "opt+enter"),
        .init(category: .intellij, label: "Step Over", iconName: "arrow.right.to.line.alt", type: .keystroke, value: "f8"),

        // PyCharm (Additional)
        .init(category: .pycharm, label: "Run Selection", iconName: "terminal.fill", type: .keystroke, value: "opt+shift+e"),
        .init(category: .pycharm, label: "Python Console", iconName: "chevron.right.2", type: .appleScript, value: "tell application \"PyCharm\" to activate"),
        .init(category: .pycharm, label: "Quick Definition", iconName: "eye.fill", type: .keystroke, value: "opt+space"),
        .init(category: .pycharm, label: "Rename Refactor", iconName: "character.cursor.ibeam", type: .keystroke, value: "shift+f6"),
        .init(category: .pycharm, label: "Search Everywhere (Double Shift)", iconName: "sparkle.magnifyingglass", type: .keystroke, value: "shift,shift"),

        // macOS System Management
        .init(category: .system, label: "Mission Control", iconName: "rectangle.3.group.fill", type: .keystroke, value: "ctrl+up"),
        .init(category: .system, label: "App Exposé", iconName: "square.stack.3d.down.right.fill", type: .keystroke, value: "ctrl+down"),
        .init(category: .system, label: "Show Desktop", iconName: "desktopcomputer", type: .keystroke, value: "cmd+f3"),
        .init(category: .system, label: "Spotlight", iconName: "magnifyingglass", type: .keystroke, value: "cmd+space"),
        .init(category: .system, label: "Stage Manager", iconName: "wand.and.stars", type: .appleScript, value: "tell application \"System Events\" to checkbox \"Stage Manager\" of group 1 of scroll area 1 of window 1 of application process \"ControlCenter\" to click"),

        // Workspace Navigation
        .init(category: .window, label: "Next Space", iconName: "arrow.right.square.fill", type: .keystroke, value: "ctrl+right"),
        .init(category: .window, label: "Previous Space", iconName: "arrow.left.square.fill", type: .keystroke, value: "ctrl+left"),
        .init(category: .window, label: "Hide App", iconName: "eye.slash.fill", type: .keystroke, value: "cmd+h"),

        // Productivity Power-Ups
        .init(category: .productivity, label: "Dictation", iconName: "mic.fill", type: .keystroke, value: "f5"),
        .init(category: .productivity, label: "Force Quit", iconName: "xmark.octagon.fill", type: .keystroke, value: "cmd+opt+esc"),
        .init(category: .productivity, label: "Empty Trash (Force)", iconName: "trash.slash.fill", type: .keystroke, value: "cmd+shift+opt+delete")
    ]
}