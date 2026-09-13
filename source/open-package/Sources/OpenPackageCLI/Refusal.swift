//
//  Refusal.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import OpenPackage

/// A refusal from the library, with the way out that only this surface can name. The
/// library says what is wrong and stops there, since what to type next is written in words
/// this command line chose.
struct Refusal: Error, CustomStringConvertible {
    // MARK: - Property
    private let error: Error

    var description: String {
        guard let next else { return cause }

        return "\(cause)\n\(next)"
    }

    /// What went wrong, which is the library's answer and the same for everyone asking.
    var cause: String { "\(error)" }

    /// What to type instead, in this surface's own words. Kept apart from the cause so a
    /// caller matching on what went wrong does not break when the advice is reworded.
    var next: String? {
        let runner = CLI.configuration.commandName ?? PackageLayout.manifest

        switch error {
        case PackageError.packageNotFound:
            return "Run '\(runner) \(BuiltinCommand.spec.rawValue)' to see what a package looks like, "
                + "or '\(runner) \(BuiltinCommand.new.rawValue) <path>' to start one."

        case RunnerError.unknownCommand, CallError.unnamed:
            return "Run '\(runner)' for the list."

        default:
            return nil
        }
    }

    // MARK: - Initializer
    init(_ error: Error) {
        self.error = error
    }

    // MARK: - Public
    /// Runs the body and re-raises whatever it refuses with the way out attached.
    static func attaching<Value>(_ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch {
            throw Refusal(error)
        }
    }

    // MARK: - Private
}
