//
//  CheckCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

struct CheckCommand: FormattedCommand {
    // MARK: - Property
    static let configuration = CommandConfiguration(
        commandName: BuiltinCommand.check.rawValue,
        abstract: "Inspect the manifest.",
        discussion: """
            Reads the manifest against the specification and nothing else. The manifest is the whole of what makes a directory a package, so how the rest of the directory is arranged is not read. Whether the package does its job is what its own commands answer.

            An error means the package is malformed and the command leaves with a non-zero status. A warning means a person should look and may legitimately decide to leave it alone, and warnings do not fail the command. What each strength means is `open-package spec`.

            WHAT IT READS
                [package] name version      Required
                [command]                   Empty bodies, and names this runner answers
                                            first, which the short form does not reach
                [package] requires          Reported when a name is not on PATH here

            EXAMPLES
                open-package check
                open-package check --json
            """
    )

    @OptionGroup
    var format: OutputFormat

    // MARK: - Initializer
    // MARK: - Public
    func execute() throws -> CommandResult<PackageRecord> {
        var inspection = try InspectionRunner(origin: Runtime().origin).run()

        // Name conflicts depend on this runner, so the library cannot report them.
        for warning in CommandName.conflicts(in: inspection.manifest) {
            inspection.diagnosis.warn(warning)
        }

        let record = PackageRecord(
            manifest: inspection.manifest,
            diagnosis: inspection.diagnosis
        )

        return CommandResult(record, status: inspection.diagnosis.isValid ? .success : .failure) {
            write(inspection)
        }
    }

    // MARK: - Private
    /// Findings go to stderr; JSON output goes to stdout.
    private func write(_ inspection: Inspection) {
        let manifest = inspection.manifest
        let diagnosis = inspection.diagnosis

        guard !diagnosis.isClean else {
            Output.write("ok  \(manifest.name) \(manifest.version) has a valid manifest")

            return
        }

        Output.writeError(diagnosis.report)
        Output.writeError("")
        Output.writeError(
            "\(manifest.name): \(diagnosis.errors.count) error · \(diagnosis.warnings.count) warn"
        )
    }
}
