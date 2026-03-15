import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    /// UserDefaults key (namespaced for production).
    static let showInDockKey = "com.vaulttoenv.showInDock"
    static let lastSaveDirectoryKey = "com.vaulttoenv.lastSaveDirectory"
    private var hotkeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyShowInDockPreference()
        registerHotkey()
        // Hide the minimal WindowGroup window (used only so SwiftUI adds the Edit menu).
        DispatchQueue.main.async { [weak self] in
            self?.hideMinimalWindowGroupWindow()
        }
    }

    private func hideMinimalWindowGroupWindow() {
        for window in NSApp.windows where window.canBecomeKey {
            // The minimal WindowGroup uses defaultSize(width: 1, height: 1).
            if window.frame.width <= 20, window.frame.height <= 20 {
                window.close()
                break
            }
        }
    }

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(string: "Convert vault or secret content (JSON, YAML, key=value) into env-format lines."),
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2025"
        ])
    }

    @objc func openHelp() {
        if let url = URL(string: "https://github.com") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func showKeyboardShortcuts() {
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
