
<div align="center">

# < DevDeck >
### The missing layer of macOS

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg)

**DevDeck** is a high-performance, native macOS productivity tool designed for developers and power users. It provides instant access to context-aware macros and a universal snippet library through an intuitive, aesthetic menu.

[Download Latest Release](https://github.com/shaf-m/devdeck/releases)

</div>

---

## 🚀 Key Features

| Feature | Description |
| :--- | :--- |
| **⌘ Powerful Macros** | Execute shell scripts, open URLs, paste text snippets, or simulate complex keystrokes with a single tap. Automate your repetitive tasks instantly. |
| **📋 Clipboard History** | Never lose a copied snippet again. Access your clipboard history directly from the radial menu and paste past items with ease. |
| **✨ Context Aware** | DevDeck adapts to the app you're using. Create specific profiles for Xcode, VS Code, Final Cut Pro, or any other app, and DevDeck switches automatically. |
| **📝 Snippet Manager** | Save and organize your frequently used code blocks. Insert them instantly into any editor without breaking your flow. |
| **🤝 Shareable Profiles** | Export your custom macro profiles and share them with your team or the community, enhancing collaboration and standardization. |
| **🔓 Open Source** | Transparent and community-driven. Inspect the code, contribute features, and build with us. |

## ⚡️ How It Works

### 1. Install & Launch
Download the app, move to Applications, and grant accessibility permissions.

### 2. Configure
Create profiles for your favorite apps. Add all your macros, snippets, and shortcuts.

### 3. Flow
Trigger the menu anywhere. Hold down the trigger key (default: `~`) or tap the icon in the menu bar to open the menu. Move your mouse to a node to execute a macro instantly.

## 🛠️ Setup & Installation

### Requirements
- macOS 13.0 or later.
- **Accessibility Permissions**: Required to monitor global hotkeys and inject keystrokes.

### Building from Source

```bash
# Clone the repository
git clone https://github.com/shafm/devdeck.git
cd devdeck

# Build the app
./scripts/build_app.sh

# Package as DMG (Optional)
./scripts/package_app.sh
```

> **Note:** The compiled app will be located at `./DevDeck.app` (or `./DevDeck.dmg` if packaged).

## 🤝 Community

DevDeck is built for anyone who wants to minimize context switching and maximize efficiency.
- **Developers**: Automate build scripts, git commands, and frequent code snippets.
- **SysAdmins**: Quick access to server management scripts and log monitors.
- **Power Users**: Simplify complex application workflows into single radial actions.

---

<div align="center">
    <i>Made for devs, by a dev.</i>
</div>
