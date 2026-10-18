//
//  RunCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

struct RunCommand: ParsableCommand {
    // MARK: - Property
    static let configuration = CommandConfiguration(
        commandName: BuiltinCommand.run.rawValue,
        abstract: "Run one of the package's own commands by name.",
        discussion: """
            Looks the name up in [command] and runs it from the package root, exactly as the short form does. Everything after the name is the command's, including anything shaped like an option, so the runner never reads it.

            Write the short form. This is for the few names the runner answers first, and for a script that would rather not know which those are.

            A name beginning with - is written `run -- <name>`. The words after this one are read as options until the terminator, so without it the name is read as one of those.

            EXAMPLES
                open-package run verify
                open-package run build a.md -o b.html
                open-package run check
                open-package run -- -x
            """
    )

    @Argument(help: "The name as [command] states it.")
    private var name: String

    // `captureForPassthrough`, so `run build --help` reaches the command, not the runner.
    @Argument(parsing: .captureForPassthrough, help: "Arguments for that command.")
    private var arguments: [String] = []

    static let formatUnavailable = "the command's own output passes through, so the runner "
        + "formats nothing here. Ask the command for JSON if it has any."

    // MARK: - Initializer
    init() { }

    // MARK: - Public
    /// Unreachable: `Passthrough` dispatches every `run` call before the parser.
    func run() throws {
        throw CallError.undispatched(BuiltinCommand.run.rawValue)
    }

    // MARK: - Private
}
