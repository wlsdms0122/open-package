//
//  Refusal.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import OpenPackage

/// A library error with this CLI's advice on what to type next.
struct Refusal: Error, CustomStringConvertible {
    // MARK: - Property
    private let error: Error

    var description: String {
        guard let next else { return cause }

        return "\(cause)\n\(next)"
    }

    var cause: String { "\(error)" }

    var next: String? {
        let runner = CLI.configuration.commandName ?? Manifest.fileName

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
    static func attaching<Value>(_ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch {
            throw Refusal(error)
        }
    }

    // MARK: - Private
}
