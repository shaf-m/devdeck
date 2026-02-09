import Cocoa

class MacroExecutor {
    static let shared = MacroExecutor()
    
    func execute(_ macro: Macro) {
        // print("Executing macro: \(macro.label)")
        switch macro.type {
        case .shellScript:
            executeShellScript(macro.value)
        case .appleScript:
            executeScript(macro.value)
        case .url:
            openURL(macro.value)
        case .keystroke:
            simulateKeystroke(macro.value, pressEnter: macro.pressEnter)
        case .text:
            simulateText(macro.value, pressEnter: macro.pressEnter)
        }
    }
    
    private func executeShellScript(_ script: String) {
        // ... (unchanged)
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", script]
        
        do {
            try task.run()
        } catch {
            print("Failed to run shell script: \(error)")
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @discardableResult
    func executeScript(_ scriptSource: String) -> String? {
        print("🍎 Running NSAppleScript: \(scriptSource)")
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            scriptObject.executeAndReturnError(&error)
            if let err = error {
                let errorString = "AppleScript Error: \(err)"
                print(errorString)
                return errorString
            } else {
                print("✅ AppleScript executed successfully")
                return nil
            }
        }
        return "Failed to initialize NSAppleScript"
    }
    
    private func simulateText(_ text: String, pressEnter: Bool) {
        // AppleScript to keystroke string
        // Note: AppleScript "keystroke" types the text. "clipboard" and paste is faster for long text,
        // but "keystroke" is simpler for basic automation.
        // Let's escape quotes in the text.
        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        
        var script = "tell application \"System Events\" to keystroke \"\(escapedText)\""
        if pressEnter {
            script += "\ntell application \"System Events\" to key code 36"
        }
        
        if let error = executeScript(script) {
            NotificationCenter.default.post(name: .macroExecutionFailed, object: nil, userInfo: ["error": error])
        }
    }
    
    private func simulateKeystroke(_ keyString: String, pressEnter: Bool) {
        // Parse "command+shift+p"
        let parts = keyString.lowercased().split(separator: "+").map { String($0) }
        var appleScriptModifiers: [String] = []
        var keyCode: CGKeyCode?
        
        for part in parts {
            switch part {
            case "cmd", "command": appleScriptModifiers.append("command down")
            case "shift": appleScriptModifiers.append("shift down")
            case "opt", "option", "alt": appleScriptModifiers.append("option down")
            case "ctrl", "control": appleScriptModifiers.append("control down")
            default:
                keyCode = KeyCodeMap.keyCode(for: part)
            }
        }
        
        guard let code = keyCode else {
            print("Unknown key code in macro: \(keyString)")
            return
        }
        
        // Construct AppleScript
        var usingString = ""
        if !appleScriptModifiers.isEmpty {
            usingString = " using {\(appleScriptModifiers.joined(separator: ", "))}"
        }
        
        var scriptSource = "tell application \"System Events\" to key code \(code)\(usingString)"
        
        if pressEnter {
             scriptSource += "\ntell application \"System Events\" to key code 36"
        }
        
        // Execute and broadcast error if any
        if let error = executeScript(scriptSource) {
            // Post notification for UI to pick up
            NotificationCenter.default.post(name: .macroExecutionFailed, object: nil, userInfo: ["error": error])
        }
    }
}

extension Notification.Name {
    static let macroExecutionFailed = Notification.Name("macroExecutionFailed")
}


