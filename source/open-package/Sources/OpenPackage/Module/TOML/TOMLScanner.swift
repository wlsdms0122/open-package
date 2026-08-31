//
//  TOMLScanner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// Reads one value from the right-hand side of an assignment. A `#` opens a comment only
/// outside a string, so `version = "1.0.0"  # note` keeps its value clean.
struct TOMLScanner {
    // MARK: - Property
    private let characters: [Character]
    private let line: Int

    private var index = 0

    // MARK: - Initializer
    init(_ text: String, line: Int) {
        self.characters = Array(text)
        self.line = line
    }

    // MARK: - Public
    mutating func value() throws -> TOMLValue {
        skipWhitespace()

        guard let head = peek() else {
            throw TOMLError(line: line, reason: "missing value")
        }

        switch head {
        case "\"":
            return .string(try string())

        case "[":
            return .array(try array())

        default:
            return try literal()
        }
    }

    mutating func expectEnd() throws {
        skipWhitespace()

        guard let head = peek(), head != "#" else { return }

        throw TOMLError(
            line: line,
            reason: "unexpected trailing text: \(String(characters[index...]))"
        )
    }

    // MARK: - Private
    private mutating func string() throws -> String {
        advance()

        var result = ""
        while let character = peek() {
            advance()

            switch character {
            case "\"":
                return result

            case "\\":
                result.append(try escape())

            default:
                result.append(character)
            }
        }

        throw TOMLError(line: line, reason: "unterminated string")
    }

    private mutating func escape() throws -> Character {
        guard let character = peek() else {
            throw TOMLError(line: line, reason: "string ends with a backslash")
        }
        advance()

        switch character {
        case "n":
            return "\n"

        case "t":
            return "\t"

        case "\"":
            return "\""

        case "\\":
            return "\\"

        default:
            throw TOMLError(line: line, reason: "unknown escape '\\\(character)'")
        }
    }

    private mutating func array() throws -> [TOMLValue] {
        advance()

        var values: [TOMLValue] = []
        while true {
            skipWhitespace()

            guard let head = peek() else {
                throw TOMLError(line: line, reason: "unterminated array")
            }

            if head == "]" {
                advance()

                return values
            }

            values.append(try value())
            skipWhitespace()

            if peek() == "," {
                advance()
            } else if peek() != "]" {
                throw TOMLError(line: line, reason: "missing ',' between array elements")
            }
        }
    }

    private mutating func literal() throws -> TOMLValue {
        var word = ""
        while let character = peek(),
            !character.isWhitespace,
            character != ",",
            character != "]",
            character != "#"
        {
            word.append(character)
            advance()
        }

        if word == "true" { return .boolean(true) }
        if word == "false" { return .boolean(false) }
        if let number = Int(word) { return .integer(number) }

        guard !word.isEmpty else {
            throw TOMLError(line: line, reason: "unreadable value")
        }

        throw TOMLError(
            line: line,
            reason: "unquoted value '\(word)'. Write strings as \"\(word)\""
        )
    }

    private func peek() -> Character? {
        index < characters.count ? characters[index] : nil
    }

    private mutating func advance() {
        index += 1
    }

    private mutating func skipWhitespace() {
        while let character = peek(), character.isWhitespace {
            advance()
        }
    }
}
