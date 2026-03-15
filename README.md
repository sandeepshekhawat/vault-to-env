# Vault to Env

[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A macOS menu bar app that converts pasted vault/secret content (JSON, YAML, or key=value) into env-format lines. Paste from anywhere, then copy the result or save as a `.env` file.

**Download:** [Releases](https://github.com/sandeepshekhawat/vault-to-env/releases) — get the latest `.app` (zip) without building.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Build and run](#build-and-run)
- [Usage](#usage)
- [Distribution](#distribution)
- [Production notes](#production-notes)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Menu bar only** by default (no dock icon). Optionally **Show in Dock** for easier access when the menu bar is crowded.
- **Input formats:** Auto (tries JSON → YAML → key=value), or force JSON, YAML, or Key=Value.
- **Output:** `KEY=value` or `export KEY=value` (toggle). Options: key style (full path vs last component), optional key prefix. Duplicate keys (e.g. with “Last component”) get suffixes `_2`, `_3`, etc.
- **Paste on open:** Clipboard content is pasted into the input area when you open the window (if input is empty).
- **Clear** input, output, or all; **Copy**, **Copy and close**, or **Save…** with brief “Copied” / “Saved” feedback; output shows key count. **Save** remembers the last directory. Large input (>500 KB) shows a warning.
- **Mask output:** Toggle to show bullets instead of values in the window (Copy/Save still use the real values).
- **Secrets cleared** when the window is closed.
- **About** and **Preferences** (paste on open, show in dock, clear clipboard on quit). **Open file…** and **drag-and-drop** to load a file into the input area.
- **Help menu** (when app is active): Vault to Env Help (opens documentation URL), Keyboard Shortcuts.
- **App icon:** Add your own PNGs to `VaultToEnvApp/Assets.xcassets/AppIcon.appiconset` (see Contents.json for sizes). Without custom icons, the app uses the system default.

## Version control (Git)

The project is set up for Git. To create a new repo or push to a remote:

```bash
cd vault-to-env-app
git init   # only if starting fresh (repo may already exist)
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/sandeepshekhawat/vault-to-env.git
git branch -M main
git push -u origin main
```

The `.gitignore` excludes Xcode build artifacts, `DerivedData`, and `xcuserdata` so they are not committed.

## Requirements

- macOS 13.0 or later
- Xcode 14+ (for building)

## Build and run

1. Open the project in Xcode:
   ```bash
   open vault-to-env-app/VaultToEnvApp.xcodeproj
   ```
2. Let Xcode resolve the Swift package dependency (Yams). If it doesn’t start automatically: **File → Packages → Resolve Package Versions**.
3. Build: **Cmd+B**.
4. Run: **Cmd+R**.

You should see a **key icon in the status bar** (top-right, near Wi‑Fi/battery). By default there is **no dock icon**. Click the key icon to open the app window. Use **Quit** in the window or **Cmd+Q** to exit.

**If the menu bar icon is hidden** (too many icons): enable **Show in Dock** in the app window so you can open it from the dock, or use **Spotlight** (Cmd+Space → type “Vault to Env” → Enter) to activate the app and show the window. When the app is active, **Cmd+Option+V** also opens or focuses the window.

**Console messages:** When running as a menu bar (agent) app, you may see “Unable to obtain a task name port right” or “ViewBridge … Terminated … NSViewBridgeErrorCanceled”. These are usually benign.

## Usage

1. Copy secret data from your vault UI, config file, or anywhere (JSON, YAML, or `KEY=value` / `KEY: value` lines).
2. Click the menu bar icon (or use Spotlight / dock if enabled). The clipboard is pasted into the input area if it’s empty.
3. Set **Format** to Auto, JSON, YAML, or Key=Value. Optionally set **Key style**, **Output** (KEY=value vs export KEY=value), and **Key prefix** (e.g. `MYAPP_`).
4. Click **Convert** (or **Cmd+Return**).
5. Use **Copy**, **Copy and close**, or **Save…** for the env output. Save uses the last chosen directory next time. Use **Clear input** / **Clear output** / **Clear all** as needed. Enable **Mask output in window** to hide values on screen.

Nested JSON/YAML is flattened (e.g. `data.api_key` → `DATA_API_KEY` with Full path, or `API_KEY` with Last component). Keys are normalized to uppercase with underscores; values that need it are quoted so `source .env` and dotenv loaders work correctly.

## Distribution

### Sharing the app (same Mac or local team)

Build an `.app` bundle and share it (zip, DMG, or copy the `.app`):

1. In Xcode: **Product → Archive** (scheme: VaultToEnvApp, **Release**).
2. In the Organizer: **Distribute App** → **Copy App** (or **Custom** to create a zip/DMG).
3. Share the `.app` or archive. Recipients copy it to **Applications** (or any folder) and double-click to run.

### Distributing via Git

- **Source only:** Push the repo to GitHub/GitLab/etc. Others clone and build in Xcode (see Build and run).
- **Releases:** On GitHub, use **Releases** to attach a built `.app` (or zip/DMG) per version so users can download without building.

For distribution outside your Mac (e.g. download from a link), code signing and notarization are recommended so macOS doesn’t block the app.

### Code signing and notarization

1. **Signing:** In Xcode, select the **VaultToEnvApp** target, **Signing & Capabilities**, and set your **Team**. Build for your target Mac(s). The app will be signed with your Developer ID.
2. **Archive:** **Product → Archive**, then **Distribute App** → **Copy App** (or **Custom** to export a zip).
3. **Notarization:** Create a zip of the `.app`, submit with `xcrun notarytool submit`, then staple the ticket. See `scripts/notarize.sh` for commands. You need an Apple ID, Team ID, and app-specific password (or keychain profile).
4. Distribute the stapled `.app` or a DMG so users can open it without Gatekeeper warnings.

## Production notes

- **Accessibility:** Buttons, toggles, and main regions have `accessibilityLabel` and `accessibilityHint` for Voice Over and other assistive technologies.
- **Errors:** Convert shows format-specific errors (e.g. "Invalid JSON", "Invalid YAML"). Save failures show the system error message instead of failing silently.
- **Key prefix:** Only alphanumeric characters and underscores are used from the key prefix; other characters are stripped so env keys stay valid.
- **Preferences:** UserDefaults keys are namespaced: `com.vaulttoenv.showInDock`, `com.vaulttoenv.lastSaveDirectory`.
- **Duplicate keys:** With “Last component” style, if multiple paths map to the same key (e.g. `a.x` and `b.x` → `X`), the second and later get `_2`, `_3`, etc. (e.g. `X_2`).
- **Secrets:** Input and output are cleared when the window closes. No secrets are logged or sent off-device.
- **Console messages:** When running as a menu bar (agent) app, messages like "Unable to obtain a task name port right", "ViewBridge … Terminated", or "binary.metallib … invalid format" are usually system-level and benign. If the app icon does not render, try a clean build and ensure you’re running for your Mac’s architecture (e.g. arm64 without Rosetta).

## Contributing

Contributions are welcome. Open an [issue](https://github.com/sandeepshekhawat/vault-to-env/issues) to discuss larger changes, or submit a pull request for small fixes. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE).
