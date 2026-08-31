//
//  RunCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

/// The long way to one of the package's own commands. `open-package <name>` is the short way
/// and is what anyone writes; it arrives everywhere except at a name this runner answers
/// first.
///
/// Without this, the short form's convenience would decide what a package may call things,
/// and which words were lost would depend on which runner was holding the package. Here the
/// manifest is read the same way by anything that can read it, and a claimed name costs the
/// short form rather than the command.
struct RunCommand: ParsableCommand {
    // MARK: - Property
    static let configuration = CommandConfiguration(
        commandName: BuiltinCommand.run.rawValue,
        abstract: "Run one of the package's own commands by name.",
        discussion: """
            Looks the name up in [command] and runs it from the package root, exactly as the short form does. Everything after the name is the command's, including anything shaped like an option, so the runner never reads it.

            Write the short form. This is for the few names the runner answers first, and for a script that would rather not know which those are.

            EXAMPLES
                open-package run verify
                open-package run build a.md -o b.html
                open-package run check
            """
    )

    @Argument(help: "The name as [command] states it.")
    private var name: String

    // `captureForPassthrough` rather than `unconditionalRemaining`, so that `run build --help`
    // is the package's business. Anything else would let the runner answer a question that was
    // addressed past it.
    @Argument(parsing: .captureForPassthrough, help: "Arguments for that command.")
    private var arguments: [String] = []

    // MARK: - Initializer
    init() { }

    // MARK: - Public
    func run() throws {
        let status = try Refusal.attaching {
            try CommandRunner(origin: Runtime().origin).run(name, arguments: arguments)
        }

        guard status == 0 else {
            throw ExitCode(status)
        }
    }

    // MARK: - Private
}
