//
//  Passthrough.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

/// Dispatches package-command calls, short or `run`, before the parser, which would reject
/// an option written before `run`'s name as unknown.
struct Passthrough {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    /// The exit code, or `nil` when the words belong to the parser.
    func status(for words: [String]) -> Int32? {
        guard let call = Call(words) else { return nil }

        let format = OutputFormat(json: call.json)

        do {
            // Judge the name before refusing `--json`, so a misspelled name is reported as such.
            guard let name = call.name else {
                // Outside a package, report that instead of the unnamed call.
                try format.refusing {
                    guard try ManifestRunner(origin: origin).run() != nil else {
                        throw PackageError.packageNotFound
                    }
                }

                try format.refuse(CallError.unnamed)
            }

            let command = try format.refusing {
                try CommandRunner(origin: origin).resolve(name)
            }

            // The command's output is its own, so the runner cannot format it as JSON.
            guard !format.json else {
                try format.write(RefusalRecord(reason: RunCommand.formatUnavailable))

                throw ExitCode.validationFailure
            }

            return try format.refusing { try command.run(call.arguments) }
        } catch let code as ExitCode {
            // Already answered.
            return code.rawValue
        } catch {
            Output.writeError("\(error)")

            return 1
        }
    }

    // MARK: - Private
}
