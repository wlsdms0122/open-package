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
struct CLI: ParsableCommand {
    // MARK: - Property
    static let configuration = CommandConfiguration(
        commandName: "open-package",
        abstract: "The runner every open-package is read by.",
        discussion: """
            This is the manual for the runner. What an open-package is, and what a manifest may say, is `open-package spec`.

            PACKAGE COMMANDS
                Any name that is not built in is looked up in [command] and run from the package root through sh, with the arguments that follow it appended unless the line places $@ itself. The command's exit code is the runner's.

                    open-package build a.md -o b.html

                Names this runner answers first, and names starting with -, are reached by putting `run` in front, and so is any other name: `open-package run build` is the same call written the long way.

                Run `open-package` with no arguments to list what the package declares, and what each of those names runs. A command's arguments are its own, so `open-package build --help` reaches the tool itself.

            WHICH PACKAGE
                The one you are standing in. The search walks up from the working directory until it finds a manifest.toml, the way a package manager does.

            SEE ALSO
                open-package spec, open-package check
            """,
        version: "open-package \(Environment.version)",
        subcommands: [
            RunCommand.self,
            CheckCommand.self,
            SpecCommand.self,
            NewCommand.self
        ]
    )

    // MARK: - Initializer
    // MARK: - Public
    /// The one fork in this binary: a word the package owns is run before the parser is
    /// given a chance at it, and everything else is the parser's.
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())

        if let status = Passthrough(origin: Runtime().origin).status(for: arguments) {
            Foundation.exit(status)
        }

        main(arguments)
    }

    /// No arguments: what this package offers, or that there is no package here.
    func run() throws {
        let manifest = try Refusal.attaching { try ManifestRunner(origin: Runtime().origin).run() }

        Output.write(UsageWriter(manifest: manifest).text())
    }

    // MARK: - Private
}
