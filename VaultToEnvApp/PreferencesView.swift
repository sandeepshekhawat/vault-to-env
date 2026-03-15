import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppDelegate.showInDockKey) private var showInDock = false
    @AppStorage(PreferencesKeys.pasteOnOpenKey) private var pasteOnOpen = true
    @AppStorage(PreferencesKeys.clearClipboardOnQuitKey) private var clearClipboardOnQuit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.title2)
            Toggle("Paste from clipboard when window opens", isOn: $pasteOnOpen)
                .toggleStyle(.switch)
            Toggle("Show in Dock", isOn: $showInDock)
                .toggleStyle(.switch)
                .onChange(of: showInDock) { _ in
                    (NSApplication.shared.delegate as? AppDelegate)?.applyShowInDockPreference()
                }
            Toggle("Clear clipboard when quitting", isOn: $clearClipboardOnQuit)
                .toggleStyle(.switch)
            Spacer()
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 380, height: 220)
    }
}

enum PreferencesKeys {
    static let pasteOnOpenKey = "com.vaulttoenv.pasteOnOpen"
    static let clearClipboardOnQuitKey = "com.vaulttoenv.clearClipboardOnQuit"
}

#Preview {
    PreferencesView()
}
