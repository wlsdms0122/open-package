//
//  TOMLParser.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// As much TOML as `manifest.toml` uses: one level of table headers, and basic strings,
/// integers, booleans and single-line arrays under them. Multi-line strings, inline tables,
/// arrays of tables, nested and quoted names, keys outside any table, and dates are refused.
/// Supporting a shape halfway leaves a place where a manifest is read differently than it
/// looks, and a shape read as some other shape is worse than one turned away.
struct TOMLParser: Sendable {
    // MARK: - Property
    // MARK: - Initializer
    init() { }

    // MARK: - Public
    func parse(_ source: String) throws -> TOMLDocument {
        var entries: [TOMLDocument.Entry] = []
        // Nil until a header is read, rather than an empty string standing in for "no table
        // yet". A key written before any header is legal TOML, and holding it under a name
        // nothing looks up would let a line of a manifest do nothing without saying so.
        var table: String?

        // Split on newline characters, not on `CharacterSet.newlines`: that set sees CR and
        // LF as two separators, so a CRLF file gains an empty line between every real one
        // and every reported number drifts further from the file a person is looking at.
        // A Character is the right unit here, since Swift already reads "\r\n" as one.
        let lines = source.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

        for (offset, rawLine) in lines.enumerated() {
            let number = offset + 1
            let line = rawLine.trimmingCharacters(in: .whitespaces)

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

    // MARK: - Private
    private func header(_ line: String, at number: Int) throws -> String {
        // Caught before the brackets come off, because `[[command]]` loses one pair to the
        // same dropFirst/dropLast a plain header uses and would arrive below as a table
        // named `[command]`: a name nothing reads, so its commands go missing in silence.
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

    /// What TOML calls a bare name: the shape this subset can both read and write back. A
    /// name outside it is either a shape that is not here, or a quoting this parser does not
    /// read, and taking it either way stores an entry under a name nothing looks up.
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

        // A dotted key is how TOML writes a table without a header. Entries are stored as
        // `table.key`, so accepting one would let `open-package.version = "1.0.0"` at the top
        // of a file mean what the `[open-package]` table means. That is a second way to say one
        // thing, which is exactly what this parser refuses to have.
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
