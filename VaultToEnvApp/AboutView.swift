import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    }

    private let helpURL = URL(string: "https://github.com/sandeepshekhawat/vault-to-env")!

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Vault to Env")
                .font(.title)
            Text("Version \(appVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Convert vault or secret content (JSON, YAML, key=value) into env-format lines. Paste, convert, then copy or save as .env.")
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)
            Link("Documentation", destination: helpURL)
                .font(.body)
            Button("OK") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 380)
    }
}

#Preview {
    AboutView()
}
