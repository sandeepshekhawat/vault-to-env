import SwiftUI

@main
struct VaultToEnvApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Group {
            // Primary UI: menu bar icon; click to open the window.
            MenuBarExtra("Vault to Env", systemImage: "key.fill") {
                ContentView()
            }
            .menuBarExtraStyle(.window)

            // Minimal WindowGroup so SwiftUI adds default Edit menu (Paste, Copy, Select All).
            // Not shown by default; user uses the MenuBarExtra window only.
            WindowGroup {
                EmptyView()
            }
            .windowResizability(.contentSize)
            .defaultSize(width: 1, height: 1)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("About Vault to Env") {
                    appDelegate.showAbout()
                }
            }
            CommandMenu("Help") {
                Button("Vault to Env Help") {
                    appDelegate.openHelp()
                }
                Button("Keyboard Shortcuts") {
                    appDelegate.showKeyboardShortcuts()
                }
            }
        }
    }
}

