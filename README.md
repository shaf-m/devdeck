# DevDeck

**DevDeck** is a high-performance, native macOS productivity tool designed for developers and power users. it provides instant access to context-aware macros and a universal snippet library through an intuitive, aesthetic radial menu.

![DevDeck UI]( DevDeck.app/Contents/Resources/AppIcon.icns ) <!-- Placeholder for potential screenshot -->

## 🚀 Key Features

### ⌘ Powerful Macros
Execute shell scripts, open URLs, paste text snippets, or simulate complex keystrokes with a single tap. Automate your repetitive tasks instantly.

### 📋 Clipboard History
Never lose a copied snippet again. Access your clipboard history directly from the radial menu and paste past items with ease.

### ✨ Context Aware
DevDeck adapts to the app you're using. Create specific profiles for Xcode, VS Code, Final Cut Pro, or any other app, and DevDeck switches automatically.

### 📝 Snippet Manager
Save and organize your frequently used code blocks. Insert them instantly into any editor without breaking your flow.

### 🤝 Shareable Profiles
Export your custom macro profiles and share them with your team or the community, enhancing collaboration and standardization.

### 🔓 Open Source
Transparent and community-driven. Inspect the code, contribute features, and build with us.

## 🛠️ Setup & Installation

### Requirements
- macOS 13.0 or later.
- **Accessibility Permissions**: As a system-wide tool, DevDeck requires accessibility permissions to monitor the global hotkey and inject keystrokes. You will be prompted on first launch.

### Building from Source

**Prerequisites:**
- Xcode 14.0 or later (for macOS SDK).

# Clone the repository
git clone https://github.com/shafm/devdeck.git
cd devdeck

# Build the app
./scripts/build_app.sh

# Package as DMG (Optional)
./scripts/package_app.sh
```

> **Note:** The compiled app will be located at `./DevDeck.app` (or `./DevDeck.dmg` if packaged).

## ⚡️ How it Works
 
1.  **Install & Launch**: Download the app, move to Applications, and grant accessibility permissions.
2.  **Configure**: Create profiles for your apps and assign a trigger key (default: `~`).
3.  **Flow**: Hold the trigger key anywhere to summon the radial menu. Move your mouse to a node to execute.

## ⌨️ Controls

- **Hold Trigger Key (`~`)**: Open Radial Menu.
- **Release Trigger Key**: Close Menu.
- **Hover & Click**: Execute macro at cursor position.
- **Click Center Hub**: Cycle active profile manually.

## 🤝 Who is DevDeck for?

DevDeck is built for anyone who wants to minimize context switching and maximize efficiency:
- **Developers**: Automate build scripts, git commands, and frequent code snippets.
- **SysAdmins**: Quick access to server management scripts and log monitors.
- **Power Users**: Simplify complex application workflows into single radial actions.

---

*DevDeck is crafted with ❤️ for the macOS ecosystem.*
