import SwiftUI

@main
struct VaultToEnvApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu bar only: no WindowGroup, no dock icon (LSUIElement in Info.plist).
        // Key icon appears in the status bar (top-right); click it to open the window.
        MenuBarExtra("Vault to Env", systemImage: "key.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}

