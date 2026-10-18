//
//  CLI.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

@main
struct CLI: FormattedCommand {
    // MARK: - Property
    static let configuration = CommandConfiguration(
        commandName: "open-package",
        abstract: "The runner every open-package is read by.",
        discussion: """
            This is the manual for the runner. What an open-package is, and what a manifest may say, is `open-package spec`.

            PACKAGE COMMANDS
                Any name that is not built in is looked up in [command] and run from the package root through sh, with the arguments that follow it appended unless the line places $@ itself. The runner becomes the command, so its terminal, signals and exit are the command's.

                    open-package build a.md -o b.html

                Names this runner answers first are reached by putting `run` in front, and so is any other name: `open-package run build` is the same call written the long way. A name starting with - needs the terminator as well, `open-package run -- -x`, since the words after `run` are read as options until it.

                Run `open-package` with no arguments to list what the package declares, and what each of those names runs. A command's arguments are its own, so `open-package build --help` reaches the tool itself.

            MACHINE-READABLE OUTPUT
                `--json` prints one line of JSON instead of text: the listing, what `check` found, the specification `spec` carries, and where `new` put a package. A refusal prints the same way, so a caller that asked for JSON is never handed prose. `run` is the exception, and not by rule: everything after the name belongs to the command, so the word reaches the package rather than the runner.

            WHICH PACKAGE
                The one you are standing in. The search walks up from the working directory until it finds a manifest.toml, the way a package manager does.

            SEE ALSO
                open-package spec, open-package check
            """,
        version: "open-package \(Environment.version)",
        subcommands: BuiltinCommand.allCases.map(\.command)
    )

    @OptionGroup
    var format: OutputFormat

    // MARK: - Initializer
    // MARK: - Public
    /// Package-command calls are dispatched before the parser; everything else is the parser's.
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())

        if let status = Passthrough(origin: Runtime().origin).status(for: arguments) {
            Foundation.exit(status)
        }

        do {
            var command = try parseAsRoot(arguments)

            try command.run()
        } catch {
            exit(withError: answered(error, asked: arguments))
        }
    }

    func execute() throws -> CommandResult<PackageRecord> {
        let manifest = try ManifestRunner(origin: Runtime().origin).run()

        return CommandResult(PackageRecord(manifest: manifest)) {
            Output.write(UsageWriter(manifest: manifest).text())
        }
    }

    // MARK: - Private
    /// Writes a parser refusal as JSON when asked, since the parser itself prints prose.
    private static func answered(_ error: Error, asked arguments: [String]) -> Error {
        let status = exitCode(for: error)

        // Built-ins already wrote their refusal, and help and version are not refusals.
        guard !(error is ExitCode), status != .success else { return error }

        let format = OutputFormat(words: arguments)

        guard format.json else { return error }

        try? format.write(RefusalRecord(reason: message(for: error)))

        return status
    }
}
