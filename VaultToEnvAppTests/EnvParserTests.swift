import XCTest
@testable import VaultToEnvApp

final class EnvParserTests: XCTestCase {

    func testParseEmptyInput() {
        switch EnvParser.parse("") {
        case .failure(let err): XCTAssertEqual(err.localizedDescription, "Input is empty.")
        case .success: XCTFail("Expected failure")
        }
    }

    func testParseJSON() {
        let input = #"{"api_key":"secret","nested":{"x":1}}"#
        guard case .success(let out) = EnvParser.parse(input) else { XCTFail(); return }
        XCTAssertTrue(out.contains("API_KEY="))
        XCTAssertTrue(out.contains("NESTED_X=1"))
    }

    func testParseJSONWithOptionsPrefix() {
        let input = #"{"a":"b"}"#
        var opts = EnvParser.Options.default
        opts.keyPrefix = "MYAPP_"
        guard case .success(let out) = EnvParser.parse(input, options: opts) else { XCTFail(); return }
        XCTAssertTrue(out.contains("MYAPP_A="))
    }

    func testParseJSONExportFormat() {
        let input = #"{"x":"y"}"#
        var opts = EnvParser.Options.default
        opts.exportFormat = .export
        guard case .success(let out) = EnvParser.parse(input, options: opts) else { XCTFail(); return }
        XCTAssertTrue(out.hasPrefix("export "))
        XCTAssertTrue(out.contains("export X="))
    }

    func testParseYAML() {
        let input = """
        key: value
        other: 42
        """
        guard case .success(let out) = EnvParser.parse(input) else { XCTFail(); return }
        XCTAssertTrue(out.contains("KEY="))
        XCTAssertTrue(out.contains("OTHER=42"))
    }

    func testParseKeyValue() {
        let input = "FOO=bar\nBAZ=qux"
        guard case .success(let out) = EnvParser.parse(input) else { XCTFail(); return }
        XCTAssertTrue(out.contains("FOO="))
        XCTAssertTrue(out.contains("BAZ="))
    }

    func testParseKeyValueColon() {
        let input = "foo: bar"
        guard case .success(let out) = EnvParser.parse(input) else { XCTFail(); return }
        XCTAssertTrue(out.contains("FOO=bar") || out.contains("FOO=\"bar\""))
    }

    func testInvalidJSON() {
        guard case .failure(let err) = EnvParser.parseAsJSONOnly("{ invalid }") else { XCTFail(); return }
        XCTAssertEqual(err.localizedDescription, "Invalid JSON.")
    }

    func testLastComponentDuplicateKeys() {
        let input = #"{"a":{"x":"1"},"b":{"x":"2"}}"#
        var opts = EnvParser.Options.default
        opts.keyStyle = .lastComponent
        guard case .success(let out) = EnvParser.parse(input, options: opts) else { XCTFail(); return }
        XCTAssertTrue(out.contains("X="))
        XCTAssertTrue(out.contains("X_2="))
    }

    func testValueQuoting() {
        let input = #"{"key":"value with spaces"}"#
        guard case .success(let out) = EnvParser.parse(input) else { XCTFail(); return }
        XCTAssertTrue(out.contains("\""))
    }

    func testLineSuffixApplied() {
        let input = #"{"FOO":"bar","BAZ":"qux"}"#
        var opts = EnvParser.Options.default
        opts.lineSuffix = ";"
        guard case .success(let out) = EnvParser.parse(input, options: opts) else { XCTFail(); return }
        let lines = out.components(separatedBy: .newlines)
        XCTAssertTrue(lines.allSatisfy { $0.hasSuffix(";") })
    }
}
