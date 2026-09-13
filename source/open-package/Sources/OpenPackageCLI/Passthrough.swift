//
//  Passthrough.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

/// Dispatches a call to one of the package's own commands, written either way, before the
/// parser sees it. `open-package build` and `run build` are the same call, and both arrive
/// here, so which words are the runner's is decided once.
///
/// The parser cannot make that decision for `run`: everything after its name is captured
/// for the package, and an option written before the name dies as one the parser does not
/// know.
struct Passthrough {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    /// The exit code to leave with, or `nil` when the arguments belong to the parser. A
    /// name this surface has not taken goes to the package first, so
    /// `open-package build -o out` does not die on an option never addressed to the runner.
    func status(for words: [String]) -> Int32? {
        guard let call = Call(words) else { return nil }

        let format = OutputFormat(json: call.json)

        do {
            // The name is judged before `--json` is refused below. The other order answers a
            // misspelled name with a sentence about JSON, and the caller never learns the
            // name was wrong.
            guard let name = call.name else {
                // Standing outside a package is the truer answer, and the advice attached to
                // a call that names nothing is to read a listing that is not there.
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

            // Only JSON is refused. The screen a command prints is its own either way, so
            // there is nothing here for the runner to choose the form of.
            guard !format.json else {
                try format.write(RefusalRecord(reason: RunCommand.formatUnavailable))

                throw ExitCode.validationFailure
            }

            return try format.refusing { try command.run(call.arguments) }
        } catch let code as ExitCode {
            // Already answered, in whichever form was asked for.
            return code.rawValue
        } catch {
            Output.writeError("\(error)")

            return 1
        }
    }

    // MARK: - Private
}
