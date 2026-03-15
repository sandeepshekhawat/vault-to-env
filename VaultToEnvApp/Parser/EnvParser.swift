import Foundation
import Yams

/// Parses vault/secret content (JSON, YAML, or key=value) into env-format lines.
enum EnvParser {

    enum KeyStyle: String, CaseIterable {
        case fullPath = "Full path"
        case lastComponent = "Last component"
    }

    enum ExportFormat: String, CaseIterable {
        case plain = "KEY=value"
        case export = "export KEY=value"
    }

    struct Options {
        var keyStyle: KeyStyle = .fullPath
        var keyPrefix: String = ""
        var exportFormat: ExportFormat = .plain
        static let `default` = Options()
    }

    /// Convert pasted text to env-formatted string (KEY=value per line).
    /// Tries JSON first, then YAML, then line-based key=value / key: value.
    static func parse(_ input: String, options: Options = .default) -> Result<String, ParseError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .failure(.emptyInput)
        }

        if let dict = parseJSON(trimmed) {
            return .success(flattenToEnv(dict, options: options))
        }
        if let dict = parseYAML(trimmed) {
            return .success(flattenToEnv(dict, options: options))
        }
        if let pairs = parseKeyValueLines(trimmed) {
            return .success(pairsToEnv(pairs, options: options))
        }
        return .failure(.unrecognizedFormat)
    }

    /// Parse only as JSON; fails if not valid JSON.
    static func parseAsJSONOnly(_ input: String, options: Options = .default) -> Result<String, ParseError> {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return .failure(.emptyInput) }
        guard let dict = parseJSON(t) else { return .failure(.invalidJSON) }
        return .success(flattenToEnv(dict, options: options))
    }

    /// Parse only as YAML; fails if not valid YAML.
    static func parseAsYAMLOnly(_ input: String, options: Options = .default) -> Result<String, ParseError> {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return .failure(.emptyInput) }
        guard let dict = parseYAML(t) else { return .failure(.invalidYAML) }
        return .success(flattenToEnv(dict, options: options))
    }

    /// Parse only as key=value or key: value lines.
    static func parseAsKeyValueOnly(_ input: String, options: Options = .default) -> Result<String, ParseError> {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return .failure(.emptyInput) }
        guard let pairs = parseKeyValueLines(t) else { return .failure(.invalidKeyValue) }
        return .success(pairsToEnv(pairs, options: options))
    }

    enum ParseError: Error, LocalizedError {
        case emptyInput
        case unrecognizedFormat
        case invalidJSON
        case invalidYAML
        case invalidKeyValue
        var errorDescription: String? {
            switch self {
            case .emptyInput: return "Input is empty."
            case .unrecognizedFormat: return "Could not parse as JSON, YAML, or key=value."
            case .invalidJSON: return "Invalid JSON."
            case .invalidYAML: return "Invalid YAML."
            case .invalidKeyValue: return "No valid key=value or key: value lines found."
            }
        }
    }

    // MARK: - JSON

    private static func parseJSON(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8) else { return nil }
        let obj = try? JSONSerialization.jsonObject(with: data)
        return obj as? [String: Any]
    }

    // MARK: - YAML

    private static func parseYAML(_ string: String) -> [String: Any]? {
        guard let node = try? Yams.load(yaml: string) else { return nil }
        return node as? [String: Any]
    }

    // MARK: - Key=value / Key: value lines

    private static func parseKeyValueLines(_ string: String) -> [(key: String, value: String)]? {
        var pairs: [(key: String, value: String)] = []
        let lines = string.components(separatedBy: .newlines)
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("#") { continue }
            if let eq = t.firstIndex(of: "=") {
                let k = String(t[..<eq]).trimmingCharacters(in: .whitespaces)
                let v = String(t[t.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
                    .unquotingEnvValue()
                if !k.isEmpty { pairs.append((normalizeKey(k), v)) }
            } else if let col = t.firstIndex(of: ":") {
                let k = String(t[..<col]).trimmingCharacters(in: .whitespaces)
                let v = String(t[t.index(after: col)...]).trimmingCharacters(in: .whitespaces)
                    .unquotingEnvValue()
                if !k.isEmpty { pairs.append((normalizeKey(k), v)) }
            }
        }
        return pairs.isEmpty ? nil : pairs
    }

    private static func normalizeKey(_ key: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let filtered = key.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        return String(filtered).uppercased()
    }

    private static func pairsToEnv(_ pairs: [(key: String, value: String)], options: Options) -> String {
        let prefix = options.keyPrefix.trimmingCharacters(in: .whitespaces)
        let withStyle = pairs
            .sorted { $0.key < $1.key }
            .map { (key: applyKeyOptions($0.key, options: options), value: $0.value) }
        let unique = uniquifyKeys(withStyle.map { ($0.key, $0.value) })
        return formatOutputLines(unique.map { (prefix + $0.0, $0.1) }, options: options)
    }

    private static func applyKeyOptions(_ key: String, options: Options) -> String {
        switch options.keyStyle {
        case .fullPath: return key
        case .lastComponent: return (key.split(separator: "_").last).map(String.init) ?? key
        }
    }

    // MARK: - Flatten dictionary (JSON / YAML)

    private static func flattenToEnv(_ dict: [String: Any], options: Options) -> String {
        let flat = flatten(dict, prefix: "")
        let prefix = options.keyPrefix.trimmingCharacters(in: .whitespaces)
        var withOptions: [(String, String)] = []
        for (k, v) in flat.sorted(by: { $0.key < $1.key }) {
            let key = applyKeyOptions(k, options: options)
            withOptions.append((prefix + key, v))
        }
        let unique = uniquifyKeys(withOptions)
        return formatOutputLines(unique, options: options)
    }

    /// When key style is lastComponent, keys can collide; suffix with _2, _3, etc.
    private static func uniquifyKeys(_ pairs: [(String, String)]) -> [(String, String)] {
        var seen: [String: Int] = [:]
        return pairs.map { key, value in
            var finalKey = key
            if let count = seen[key] {
                seen[key] = count + 1
                finalKey = "\(key)_\(count + 1)"
            } else {
                seen[key] = 1
            }
            return (finalKey, value)
        }
    }

    private static func formatOutputLines(_ pairs: [(String, String)], options: Options) -> String {
        let lines = pairs.map { escapeEnvLine(key: $0.0, value: $0.1) }
        if options.exportFormat == .export {
            return lines.map { "export \($0)" }.joined(separator: "\n")
        }
        return lines.joined(separator: "\n")
    }

    private static func flatten(_ dict: [String: Any], prefix: String) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dict {
            let nextPrefix = prefix.isEmpty ? key : "\(prefix)_\(key)"
            let envKey = normalizeKey(nextPrefix)
            if let str = value as? String {
                result[envKey] = str
            } else if let nested = value as? [String: Any] {
                result.merge(flatten(nested, prefix: nextPrefix), uniquingKeysWith: { $1 })
            } else if let arr = value as? [Any] {
                for (idx, item) in arr.enumerated() {
                    if let str = item as? String {
                        result["\(envKey)_\(idx)"] = str
                    } else if let nested = item as? [String: Any] {
                        result.merge(flatten(nested, prefix: "\(nextPrefix)_\(idx)"), uniquingKeysWith: { $1 })
                    }
                }
            } else if let num = value as? NSNumber {
                result[envKey] = num.stringValue
            } else if value is NSNull {
                result[envKey] = ""
            }
        }
        return result
    }

    // MARK: - Escaping for .env

    private static func escapeEnvLine(key: String, value: String) -> String {
        let escaped = value.escapeForEnv()
        return "\(key)=\(escaped)"
    }
}

// MARK: - String helpers

private extension String {
    /// Remove surrounding quotes if present (for pasted key=value lines).
    func unquotingEnvValue() -> String {
        var s = self
        if s.hasPrefix("\"") && s.hasSuffix("\"") && s.count >= 2 {
            s = String(s.dropFirst().dropLast())
            s = s.replacingOccurrences(of: "\\\"", with: "\"")
        }
        if s.hasPrefix("'") && s.hasSuffix("'") && s.count >= 2 {
            s = String(s.dropFirst().dropLast())
        }
        return s
    }

    /// Quote and escape for .env so `source` / dotenv work.
    func escapeForEnv() -> String {
        if isEmpty { return "\"\"" }
        let needsQuotes = contains(" ") || contains("\"") || contains("\\") || contains("\n") || contains("#") || contains("$")
        if !needsQuotes { return self }
        let escaped = self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }
}
