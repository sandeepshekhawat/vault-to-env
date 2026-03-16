import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var errorMessage: String?
    @State private var inputFormat: InputFormat = .auto
    @State private var copyFeedback = false
    @State private var saveFeedback = false
    @State private var hasPastedOnOpen = false
    @AppStorage(AppDelegate.showInDockKey) private var showInDock = false
    @State private var keyStyle: EnvParser.KeyStyle = .fullPath
    @State private var keyPrefix: String = ""
    @State private var exportFormat: EnvParser.ExportFormat = .plain
    @State private var maskOutput = false
    @State private var saveErrorMessage: String?
    @State private var copyFeedbackWorkItem: DispatchWorkItem?
    @State private var showAbout = false
    @State private var showPreferences = false

    enum InputFormat: String, CaseIterable {
        case auto = "Auto"
        case json = "JSON"
        case yaml = "YAML"
        case keyValue = "Key=Value"
    }

    private var outputKeyCount: Int {
        outputText.isEmpty ? 0 : outputText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }

    private static let largeInputThreshold = 500_000
    private var inputSizeWarning: String? {
        let count = inputText.utf8.count
        guard count > Self.largeInputThreshold else { return nil }
        let mb = Double(count) / 1_000_000
        return String(format: "Large input (%.1f MB). Conversion may be slow.", mb)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Input section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Paste vault/secret content")
                        .font(.headline)
                    Picker("Format", selection: $inputFormat) {
                        ForEach(InputFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    .accessibilityLabel("Input format")
                    .accessibilityHint("Auto, JSON, YAML, or Key=Value")
                    Spacer()
                    Button("Paste", action: pasteFromClipboard)
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Paste from clipboard into input")
                    Button("Open file…", action: openFile)
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Open file into input")
                    Button("Clear input", action: clearInput)
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Clear input")
                }
                TextEditor(text: $inputText)
                    .accessibilityLabel("Vault or secret content input")
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .frame(minHeight: 100, maxHeight: 140)
                if inputSizeWarning != nil {
                    Text(inputSizeWarning!)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // Parser options
            HStack(spacing: 12) {
                Picker("Key style", selection: $keyStyle) {
                    ForEach(EnvParser.KeyStyle.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                Picker("Output", selection: $exportFormat) {
                    ForEach(EnvParser.ExportFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
                TextField("Key prefix (e.g. MYAPP_)", text: $keyPrefix)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 140)
            }

            // Convert button
            Button(action: convert) {
                Label("Convert", systemImage: "arrow.down.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: .command)
            .accessibilityLabel("Convert to env format")
            .accessibilityHint("Parses input and fills the env output area")

            if let err = errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Error")
                    .accessibilityValue(err)
            }
            if let err = saveErrorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Save error")
                    .accessibilityValue(err)
            }

            // Output section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Env output")
                        .font(.headline)
                    if outputKeyCount > 0 {
                        Text("(\(outputKeyCount) keys)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Clear output", action: clearOutput)
                        .buttonStyle(.borderless)
                }
                TextEditor(text: .constant(maskOutput ? masked(outputText) : outputText))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .frame(minHeight: 100, maxHeight: 160)
                    .accessibilityLabel("Env output")
                    .accessibilityValue(outputKeyCount > 0 ? "\(outputKeyCount) keys" : "Empty")

                Toggle("Mask output in window", isOn: $maskOutput)
                    .toggleStyle(.switch)
                    .accessibilityLabel("Mask output in window")
                    .accessibilityHint("Shows bullets instead of values; Copy and Save still use real values")

                HStack(spacing: 8) {
                    Button(action: copyOutput) {
                        HStack(spacing: 4) {
                            Label(copyFeedback ? "Copied" : "Copy", systemImage: copyFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                        }
                    }
                    .disabled(outputText.isEmpty)
                    .accessibilityLabel(copyFeedback ? "Copied to clipboard" : "Copy output to clipboard")

                    Button(action: copyAndClose) {
                        Label("Copy and close", systemImage: "doc.on.doc.fill")
                    }
                    .disabled(outputText.isEmpty)
                    .accessibilityLabel("Copy output to clipboard and close window")

                    Button(action: saveToFile) {
                        HStack(spacing: 4) {
                            Label(saveFeedback ? "Saved" : "Save…", systemImage: saveFeedback ? "checkmark.circle.fill" : "square.and.arrow.down")
                        }
                    }
                    .disabled(outputText.isEmpty)
                    .accessibilityLabel(saveFeedback ? "Saved to file" : "Save output to file")

                    Button("Clear all", action: clearAll)
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                        .accessibilityLabel("Clear all input and output")
                }

                Divider()
                    .padding(.vertical, 4)

                Toggle("Show in Dock", isOn: $showInDock)
                    .toggleStyle(.switch)
                    .onChange(of: showInDock) { _ in
                        (NSApplication.shared.delegate as? AppDelegate)?.applyShowInDockPreference()
                    }
                    .accessibilityLabel("Show app icon in the Dock")
                    .accessibilityHint("Useful when the menu bar icon is hidden")

                HStack(spacing: 12) {
                    Button("Preferences…", action: { showPreferences = true })
                        .accessibilityLabel("Open preferences")
                    Button("About", action: { showAbout = true })
                        .accessibilityLabel("About Vault to Env")
                    Button(role: .destructive, action: quit) {
                        Label("Quit Vault to Env", systemImage: "power")
                    }
                    .keyboardShortcut("q", modifiers: .command)
                }

                Text("Vault to Env \(appVersion)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(width: 520, height: 560)
        .onAppear(perform: pasteFromClipboardIfNeeded)
        .onDisappear(perform: clearAll)
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showPreferences) { PreferencesView() }
        .onDrop(of: [.fileURL, .plainText], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText, .json]
        if let lastDir = UserDefaults.standard.string(forKey: AppDelegate.lastSaveDirectoryKey), !lastDir.isEmpty {
            let dirURL = URL(fileURLWithPath: lastDir)
            if (try? dirURL.checkResourceIsReachable()) == true { panel.directoryURL = dirURL }
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            inputText = try String(contentsOf: url, encoding: .utf8)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first,
              provider.hasItemConformingToTypeIdentifier("public.file-url") else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\"")),
                  let url = URL(string: path) else { return }
            DispatchQueue.main.async {
                do {
                    inputText = try String(contentsOf: url, encoding: .utf8)
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        return true
    }

    private func masked(_ s: String) -> String {
        s.map { c in c.isNewline ? c : Character("\u{2022}") }.map(String.init).joined()
    }

    private func pasteFromClipboard() {
        if let clip = NSPasteboard.general.string(forType: .string) {
            inputText += clip
        }
    }

    private func pasteFromClipboardIfNeeded() {
        guard (UserDefaults.standard.object(forKey: PreferencesKeys.pasteOnOpenKey) as? Bool) ?? true,
              !hasPastedOnOpen, inputText.isEmpty else { return }
        if let clip = NSPasteboard.general.string(forType: .string), !clip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputText = clip
            hasPastedOnOpen = true
        }
    }

    private func clearInput() {
        inputText = ""
        errorMessage = nil
        saveErrorMessage = nil
    }

    private func clearOutput() {
        outputText = ""
        saveErrorMessage = nil
    }

    private func clearAll() {
        inputText = ""
        outputText = ""
        errorMessage = nil
        saveErrorMessage = nil
    }

    /// Key prefix sanitized for env (alphanumeric + underscore only).
    private var sanitizedKeyPrefix: String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return keyPrefix.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()
    }

    private var parserOptions: EnvParser.Options {
        var options = EnvParser.Options(keyStyle: keyStyle, keyPrefix: sanitizedKeyPrefix, exportFormat: exportFormat)
        options.lineSuffix = ";"
        return options
    }

    private func convert() {
        errorMessage = nil
        saveErrorMessage = nil
        let options = parserOptions
        let result: Result<String, EnvParser.ParseError>
        switch inputFormat {
        case .auto:
            result = EnvParser.parse(inputText, options: options)
        case .json:
            result = EnvParser.parseAsJSONOnly(inputText, options: options)
        case .yaml:
            result = EnvParser.parseAsYAMLOnly(inputText, options: options)
        case .keyValue:
            result = EnvParser.parseAsKeyValueOnly(inputText, options: options)
        }
        switch result {
        case .success(let env):
            outputText = env
        case .failure(let err):
            errorMessage = err.localizedDescription
            outputText = ""
        }
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    }

    private func copyOutput() {
        copyFeedbackWorkItem?.cancel()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        copyFeedback = true
        let work = DispatchWorkItem { copyFeedback = false }
        copyFeedbackWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func copyAndClose() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        NSApp.windows.first(where: { $0.canBecomeKey })?.close()
    }

    private func saveToFile() {
        saveErrorMessage = nil
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = ".env"
        panel.canCreateDirectories = true
        if let lastDir = UserDefaults.standard.string(forKey: AppDelegate.lastSaveDirectoryKey), !lastDir.isEmpty {
            let dirURL = URL(fileURLWithPath: lastDir)
            if (try? dirURL.checkResourceIsReachable()) == true {
                panel.directoryURL = dirURL
            }
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try outputText.write(to: url, atomically: true, encoding: .utf8)
            UserDefaults.standard.set(url.deletingLastPathComponent().path, forKey: AppDelegate.lastSaveDirectoryKey)
            saveFeedback = true
            saveErrorMessage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saveFeedback = false }
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    ContentView()
        .frame(width: 480, height: 420)
}
