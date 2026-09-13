//
//  OutputFormat.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import ArgumentParser
import Foundation
import OpenPackage

/// Which of the two forms the runner's own output takes, and the one place that choice is
/// acted on.
///
/// One type adopted everywhere rather than a flag per command. The parser resolves a flag
/// against the whole command tree, so the root's declaration alone makes `--json` accepted
/// in front of any built-in, and a built-in that does not read it does not reject the word
/// either. Every built-in therefore answers for it, and the one with nothing to format
/// refuses it out loud.
struct OutputFormat: ParsableArguments {
    // MARK: - Property
    /// Spelled once. The parser registers this name and `Call` looks for it in raw words,
    /// and two literals would drift into a word the parser knows and the fork does not.
    static let name = "json"
    static var flag: String { "--\(name)" }

    @Flag(name: .customLong(name), help: "Print one line of JSON instead of text for a person.")
    var json = false

    // MARK: - Initializer
    init() { }

    /// For the one caller that reads the word out of raw words rather than being handed it
    /// by the parser. Taken as a value so that the state stays this type's own.
    init(json: Bool) {
        self.json = json
    }

    /// For the fork that runs where the parser has read nothing, and the word is still in
    /// the raw words. Anywhere among them, since the parser takes it anywhere.
    init(words: [String]) {
        self.json = words.contains(Self.flag)
    }

    // MARK: - Public
    /// Writes one record, in the form that was asked for.
    func write(_ record: some EnvelopeRecord, render: () -> Void) throws {
        guard json else {
            render()

            return
        }

        try writeJSON(record)
    }

    /// Writes one record where JSON was asked for, and leaves the prose to whoever raised it.
    /// The parser words and prints its own, which is the one output the runner does not.
    func write(_ record: some EnvelopeRecord) throws {
        try write(record) { }
    }

    /// Runs the work, and writes whatever it refuses in the same form. Attaching the way
    /// out is folded in here, since written at the call site it is two wrappings in a fixed
    /// order that a built-in can get half right.
    func refusing<Value>(_ work: () throws -> Value) throws -> Value {
        do {
            return try Refusal.attaching(work)
        } catch {
            guard json else { throw error }

            // Already a refusal: `Refusal.attaching` above put the way out on it. Wrapping
            // it again would fold that sentence back into the cause, which is the seam this
            // record exists to keep apart.
            try writeJSON(RefusalRecord(error as? Refusal ?? Refusal(error)))

            throw ExitCode.failure
        }
    }

    /// Refuses the call itself, in whichever form was asked for. It leaves rather than
    /// returning a status to leave with, which a caller can forget to raise.
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
    /// Sorted, so two runs of the same question produce identical bytes. Slashes unescaped,
    /// because a command line holds paths and `source\/build.sh` is the same string spelled
    /// in a way nobody reading the output expects.
    private func writeJSON(_ record: some EnvelopeRecord) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        Output.write(String(decoding: try encoder.encode(Envelope(record)), as: UTF8.self))
    }
}
