# DevDeck

**DevDeck** is a high-performance, native macOS productivity tool designed for developers and power users. it provides instant access to context-aware macros and a universal snippet library through an intuitive, aesthetic radial menu.

![DevDeck UI]( DevDeck.app/Contents/Resources/AppIcon.icns ) <!-- Placeholder for potential screenshot -->

## 🚀 Key Features

### 🎡 Dynamic Radial Menu
The heart of DevDeck. Triggered by a global hotkey, it gives you a glassmorphic dashboard of actions centered around your cursor.
- **Instant Access**: Hold the `~` (Tilde) key to summon the menu.
- **Quick Execute**: Use keys `1-6` or click a node to trigger a macro.
- **Smart Hub**: The center hub displays the current profile and allows manual cycling with a click.

### 🧠 Context-Aware Profiles
Never search for the right shortcut again. DevDeck automatically detects your active application and switches to the relevant profile.
- **Auto-Switch**: Focused on VS Code? Your "Coding" macros appear. Switched to Safari? Your "Browsing" macros are ready.
- **Custom Links**: Easily link any macOS application bundle ID to a specific profile.

### 🛠️ Powerful Macros
Automate anything with various macro types:
- **Shell Scripts**: Run terminal commands in the background.
- **AppleScript**: Control system-level apps and settings.
- **Keystrokes**: Simulate complex keyboard shortcuts (e.g., `Cmd+Option+I`).
- **Text Injection**: Paste pre-defined templates or boilerplates instantly.

### 📚 Universal Snippet Library
A persistent home for your most used code blocks, accessible across all your editors.
- **Library Sidebar**: Organize snippets with languages, notes, and pinning.
- **Drag & Drop**: Drag snippets directly into your macros to create text-paste actions.
- **Search & Pin**: Keep your most important snippets at the top.

### 📤 Import & Export
Share your workflows with others or keep backups of your custom profiles using standard JSON files.

## 🛠️ Setup & Installation

### Requirements
- macOS 13.0 or later.
- **Accessibility Permissions**: As a system-wide tool, DevDeck requires accessibility permissions to monitor the global hotkey and inject keystrokes. You will be prompted on first launch.

### Building from Source
```bash
# Clone the repository
git clone https://github.com/shafm/devdeck.git
cd devdeck

# Build using the provided script
bash scripts/build_app.sh
```

## ⌨️ Global Controls

- **Hold `~` (Tilde)**: Show Radial Menu.
- **Release `~`**: Hide Radial Menu.
- **Press `1-6`**: Execute the macro at the corresponding position while the menu is open.
- **Click Center Hub**: Cycle to the next available profile manually.
- **`Esc`**: Close the menu without executing.

## 🤝 Who is DevDeck for?

DevDeck is built for anyone who wants to minimize context switching and maximize efficiency:
- **Developers**: Automate build scripts, git commands, and frequent code snippets.
- **SysAdmins**: Quick access to server management scripts and log monitors.
- **Power Users**: Simplify complex application workflows into single radial actions.

---

*DevDeck is crafted with ❤️ for the macOS ecosystem.*
