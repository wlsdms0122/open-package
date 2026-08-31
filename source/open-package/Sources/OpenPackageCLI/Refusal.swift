//
//  Refusal.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import OpenPackage

/// A refusal from the library, with the way out that only this surface can name.
///
/// The library says what is wrong and stops there, because what to type next is written in
/// words this command line chose. Another surface over the same library would answer to
/// different ones, and none of them are the library's to know.
struct Refusal: Error, CustomStringConvertible {
    // MARK: - Property
    private let error: Error

    var description: String {
        guard let next else { return "\(error)" }

        return "\(error)\n\(next)"
    }

    private var next: String? {
        let runner = CLI.configuration.commandName ?? PackageLayout.manifest

        switch error {
        case PackageError.packageNotFound:
            return "Run '\(runner) \(BuiltinCommand.spec.rawValue)' to see what a package looks like, "
                + "or '\(runner) \(BuiltinCommand.new.rawValue) <path>' to start one."

        case RunnerError.unknownCommand:
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
    static func attaching<Answer>(_ body: () throws -> Answer) throws -> Answer {
        do {
            return try body()
        } catch {
            throw Refusal(error)
        }
    }

    // MARK: - Private
}
