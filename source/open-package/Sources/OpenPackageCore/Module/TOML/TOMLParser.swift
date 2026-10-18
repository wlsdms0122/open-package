//
//  TOMLParser.swift
//  OpenPackageCore
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// The TOML subset `manifest.toml` uses: one level of table headers, with basic strings,
/// integers, booleans and single-line arrays. Anything else is refused.
package struct TOMLParser: Sendable {
    // MARK: - Property
    // MARK: - Initializer
    package init() { }

    // MARK: - Public
    package func parse(_ source: String) throws -> TOMLDocument {
        var entries: [TOMLDocument.Entry] = []
        // Nil before the first header, so a key outside any table is refused, not stored.
        var table: String?

        for (offset, line) in lines(of: source).enumerated() {
            let number = offset + 1

            if line.isEmpty || line.hasPrefix("#") { continue }

            if line.hasPrefix("[") {
                table = try header(line, at: number)
                continue
            }

            let entry = try assignment(line, in: table, at: number)
            guard !entries.contains(where: { $0.key == entry.key }) else {
                throw TOMLError(line: number, reason: "'\(entry.key)' is defined twice")
            }

            entries.append(entry)
        }

        return TOMLDocument(entries: entries)
    }

    /// Reads header lines alone, so a source `parse` refuses still names its tables.
    package func tableNames(in source: String) -> [String] {
        lines(of: source).compactMap { line in
            guard line.hasPrefix("["), !line.hasPrefix("[["),
                let close = line.firstIndex(of: "]")
            else { return nil }

            let name = line[line.index(after: line.startIndex)..<close].trimmingCharacters(in: .whitespaces)
            let quotes: Set<Character> = ["\"", "'"]
            guard name.count >= 2, let first = name.first, first == name.last, quotes.contains(first) else {
                return name
            }

            return String(name.dropFirst().dropLast())
        }
    }

    // MARK: - Private
    /// Splits on `Character.isNewline`, not `CharacterSet.newlines`, which splits CRLF in two
    /// and skews every reported line number.
    private func lines(of source: String) -> [String] {
        source
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func header(_ line: String, at number: Int) throws -> String {
        // Checked before stripping brackets, or `[[command]]` becomes a table named `[command]`.
        guard !line.hasPrefix("[[") else {
            throw TOMLError(line: number, reason: "an array of tables is not read here")
        }
        guard line.hasSuffix("]") else {
            throw TOMLError(line: number, reason: "table header is not closed with ']'")
        }

        let name = String(line.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            throw TOMLError(line: number, reason: "empty table name")
        }
        guard !name.contains(".") else {
            throw TOMLError(line: number, reason: "'\(name)' is a nested table; tables here have one level")
        }
        try bare(name, "table name", at: number)

        return name
    }

    /// Only bare names; anything else would be stored under a key nothing looks up.
    private func bare(_ name: String, _ role: String, at number: Int) throws {
        guard name.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") }) else {
            throw TOMLError(line: number, reason: "'\(name)' is not a \(role)")
        }
    }

    private func assignment(
        _ line: String,
        in table: String?,
        at number: Int
    ) throws -> TOMLDocument.Entry {
        guard let separator = line.firstIndex(of: "=") else {
            throw TOMLError(line: number, reason: "expected 'key = value', found: \(line)")
        }

        let key = String(line[line.startIndex..<separator]).trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else {
            throw TOMLError(line: number, reason: "empty key")
        }

        // A dotted key would be a second way to write a table.
        guard !key.contains(".") else {
            throw TOMLError(line: number, reason: "'\(key)' is a dotted key; write a [table] header")
        }
        try bare(key, "key", at: number)

        guard let table else {
            throw TOMLError(line: number, reason: "'\(key)' is written before any [table] header")
        }

        var scanner = TOMLScanner(String(line[line.index(after: separator)...]), line: number)
        let value = try scanner.value()
        try scanner.expectEnd()

        return TOMLDocument.Entry(
            key: "\(table).\(key)",
            value: value,
            line: number
        )
    }
}
