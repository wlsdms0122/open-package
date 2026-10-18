//
//  TOMLDocument.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// Entries keyed as `table.key`, in file order, which is the order commands are listed in.
struct TOMLDocument: Sendable {
    // MARK: - Property
    let entries: [Entry]

    // MARK: - Initializer
    init(entries: [Entry]) {
        self.entries = entries
    }

    // MARK: - Public
    /// Throws on a non-string value rather than rendering it: `version = 1` is not `"1"`.
    func string(_ key: String) throws -> String? {
        guard let entry = entry(key) else { return nil }
        guard case let .string(text) = entry.value else {
            throw TOMLError(line: entry.line, reason: "'\(key)' must be a string")
        }

        return text
    }

    func strings(_ key: String) throws -> [String] {
        guard let entry = entry(key) else { return [] }
        guard case let .array(values) = entry.value else {
            throw TOMLError(line: entry.line, reason: "'\(key)' must be an array of strings")
        }

        return try values.map { value in
            guard case let .string(text) = value else {
                throw TOMLError(line: entry.line, reason: "'\(key)' must hold strings only")
            }

            return text
        }
    }

    func table(_ name: String) -> [Entry] {
        let prefix = "\(name)."

        return entries.compactMap { entry in
            guard entry.key.hasPrefix(prefix) else { return nil }

            return Entry(
                key: String(entry.key.dropFirst(prefix.count)),
                value: entry.value,
                line: entry.line
            )
        }
    }

    // MARK: - Private
    private func entry(_ key: String) -> Entry? {
        entries.first { $0.key == key }
    }
}

extension TOMLDocument {
    struct Entry: Equatable, Sendable {
        // MARK: - Property
        let key: String
        let value: TOMLValue
        /// Kept so errors raised after parsing can name the line.
        let line: Int

        // MARK: - Initializer
        init(key: String, value: TOMLValue, line: Int) {
            self.key = key
            self.value = value
            self.line = line
        }

        // MARK: - Public
        // MARK: - Private
    }
}
