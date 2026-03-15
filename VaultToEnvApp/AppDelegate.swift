import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    /// UserDefaults key (namespaced for production).
    static let showInDockKey = "com.vaulttoenv.showInDock"
    static let lastSaveDirectoryKey = "com.vaulttoenv.lastSaveDirectory"
    private var hotkeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyShowInDockPreference()
        registerHotkey()
        setupHelpMenu()
    }

    private func setupHelpMenu() {
        let mainMenu = NSMenu()
        let appMenu = NSMenu()
        let appItem = NSMenuItem(title: "Vault to Env", action: nil, keyEquivalent: "")
        appItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "About Vault to Env", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Vault to Env", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        mainMenu.addItem(appItem)

        // Edit menu so Paste (⌘V), Copy (⌘C), etc. work in the input/output fields.
        let editMenu = NSMenu(title: "Edit")
        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "Undo", action: NSSelectorFromString("undo:"), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: NSSelectorFromString("redo:"), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: NSSelectorFromString("cut:"), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: NSSelectorFromString("copy:"), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: NSSelectorFromString("paste:"), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: NSSelectorFromString("selectAll:"), keyEquivalent: "a"))
        mainMenu.addItem(editItem)

        let helpMenu = NSMenu()
        let helpItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        helpItem.submenu = helpMenu
        helpMenu.addItem(NSMenuItem(title: "Vault to Env Help", action: #selector(openHelp), keyEquivalent: ""))
        helpMenu.addItem(NSMenuItem(title: "Keyboard Shortcuts", action: #selector(showKeyboardShortcuts), keyEquivalent: ""))
        mainMenu.addItem(helpItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(string: "Convert vault or secret content (JSON, YAML, key=value) into env-format lines."),
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2025"
        ])
    }

    @objc private func openHelp() {
        if let url = URL(string: "https://github.com") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showKeyboardShortcuts() {
        let msg = """
        Convert: ⌘↩
        Copy and close: (button in window)
        Clear all: ⇧⌘C
        Open / focus window: ⌘⌥V (when app is active)
        Quit: ⌘Q
        """
        let alert = NSAlert()
        alert.messageText = "Keyboard Shortcuts"
        alert.informativeText = msg
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func registerHotkey() {
        hotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.command, .option]), event.characters == "v" else { return event }
            self?.showMainWindow()
            return nil
        }
    }

    func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Re-apply menu so Edit (Paste, Copy, etc.) is present after SwiftUI may have replaced it.
        setupHelpMenu()
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func applyShowInDockPreference() {
        let show = UserDefaults.standard.bool(forKey: Self.showInDockKey)
        NSApp.setActivationPolicy(show ? .regular : .accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: PreferencesKeys.clearClipboardOnQuitKey) {
            NSPasteboard.general.clearContents()
        }
    }
}
