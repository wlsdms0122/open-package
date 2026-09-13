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
/// manifest is read the same way by anything that can read it, and a name the runner has
/// taken costs the short form rather than the command.
struct RunCommand: PassthroughCommand {
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

    // `captureForPassthrough` rather than `unconditionalRemaining`, so that `run build --help`
    // is the package's business. Anything else would let the runner answer a question that was
    // addressed past it.
    @Argument(parsing: .captureForPassthrough, help: "Arguments for that command.")
    private var arguments: [String] = []

    /// Said here and used by the short form too, which is this command written shorter, so
    /// it names neither spelling.
    static let formatUnavailable = "the command's own output passes through, so the runner "
        + "formats nothing here. Ask the command for JSON if it has any."

    // MARK: - Initializer
    init() { }

    // MARK: - Public

    // MARK: - Private
}
