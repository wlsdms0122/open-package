//
//  OutputFormat.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import ArgumentParser
import Foundation
import OpenPackage

/// Adopted by every built-in because the parser accepts `--json` before any of them, so each
/// must honor or refuse it.
struct OutputFormat: ParsableArguments {
    // MARK: - Property
    /// Also matched in raw words by `Call`, so keep one spelling.
    static let name = "json"
    static var flag: String { "--\(name)" }

    @Flag(name: .customLong(name), help: "Print one line of JSON instead of text for a person.")
    var json = false

    // MARK: - Initializer
    init() { }

    init(json: Bool) {
        self.json = json
    }

    /// For use before parsing; the flag may appear anywhere.
    init(words: [String]) {
        self.json = words.contains(Self.flag)
    }

    // MARK: - Public
    func write(_ record: some Encodable, render: () -> Void) throws {
        guard json else {
            render()

            return
        }

        try writeJSON(record)
    }

    /// Writes JSON only; in text mode the prose is left to whoever raised it.
    func write(_ record: some Encodable) throws {
        try write(record) { }
    }

    /// Runs the work and writes its refusal, with advice attached, in the requested form.
    func refusing<Value>(_ work: () throws -> Value) throws -> Value {
        do {
            return try Refusal.attaching(work)
        } catch {
            guard json else { throw error }

            // Do not re-wrap a `Refusal`, or its advice merges into the cause.
            try writeJSON(RefusalRecord(error as? Refusal ?? Refusal(error)))

            throw ExitCode.failure
        }
    }

    /// Never returns, so a caller cannot forget to exit.
    func refuse(_ error: some Error & CustomStringConvertible) throws -> Never {
        let refusal = Refusal(error)

        if json {
            try writeJSON(RefusalRecord(refusal))
        } else {
            Output.writeError("\(refusal)")
        }

        throw ExitCode.validationFailure
    }

    // MARK: - Private
    /// Sorted keys for stable output; slashes unescaped since the output holds paths.
    private func writeJSON(_ record: some Encodable) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        Output.write(String(decoding: try encoder.encode(Envelope(record)), as: UTF8.self))
    }
}
