//
//  NewCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

struct NewCommand: FormattedCommand {
    // MARK: - Property
    static let configuration = CommandConfiguration(
        commandName: BuiltinCommand.new.rawValue,
        abstract: "Create a package.",
        discussion: """
            Writes the skeleton: manifest.toml, README.md, source/ and document/, and nothing else.

            The directory name is where [package] name starts, and the two are free to differ from the first edit. An existing path is refused rather than written over.

            The skeleton declares one command, and it fails until it is written, so that nothing unwritten passes. Filling in name and description and replacing that line is the first job. The name is only what packages tend to reach for; the specification fixes none.

            EXAMPLES
                open-package new ../sample-package
                open-package new /tmp/scratch-package
                open-package new ../sample-package --json
            """
    )

    @Argument(help: "Where to create the package. Its last component becomes the package id.")
    var path: String

    @OptionGroup
    var format: OutputFormat

    // MARK: - Initializer
    // MARK: - Public
    func execute() throws -> CommandResult<CreationRecord> {
        let destination = Runtime().resolve(path)
        let name = try CreationRunner().run(at: destination)
        let record = CreationRecord(created: destination.path, name: name)

        return CommandResult(record) {
            Output.write("created  \(destination.path)")
            Output.write("")
            Output.write("Next, fill in name and description in \(PackageLayout.manifest), then write a command that answers.")
            Output.write("Do not describe what success looks like in prose; let the command answer with its exit code.")
        }
    }

    // MARK: - Private
}
