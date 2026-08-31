//
//  CheckCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

struct CheckCommand: ParsableCommand {
    // MARK: - Property
    static let configuration = CommandConfiguration(
        commandName: BuiltinCommand.check.rawValue,
        abstract: "Inspect the layout and the manifest.",
        discussion: """
            Reads the package against the specification and nothing else. Whether the package does its job is what its own commands answer, and this only asks whether it is a package.

            An error means the package is malformed and the command leaves with a non-zero status. A warning means a person should look and may legitimately decide to leave it alone, and warnings do not fail the command. Only the manifest can raise an error. What each strength means is `open-package spec`.

            WHAT IT READS
                [package] name version      Required
                [command]                   Empty bodies, and names this runner answers
                                            first, which the short form does not reach
                README.md                   Reported when absent
                source/ or document/        Reported when neither is there
                Top level                   Anything outside the usual shape is reported
                [package] requires          Reported when a name is not on PATH here

            EXAMPLES
                open-package check
            """
    )

    // MARK: - Initializer
    // MARK: - Public
    func run() throws {
        var inspection = try Refusal.attaching { try InspectionRunner(origin: Runtime().origin).run() }

        // The library judged the package against the specification; a name this runner has
        // already spent is something only this side can see.
        for warning in CommandName.claims(in: inspection.manifest) {
            inspection.diagnosis.warn(warning)
        }

        let manifest = inspection.manifest
        let diagnosis = inspection.diagnosis

        guard !diagnosis.isClean else {
            Output.write("ok  \(manifest.name) \(manifest.version) is sound in layout and manifest")

            return
        }

        Output.writeError(diagnosis.report)
        Output.writeError("")
        Output.writeError(
            "\(manifest.name): \(diagnosis.errors.count) error · \(diagnosis.warnings.count) warn"
        )

        guard diagnosis.isSound else {
            throw ExitCode.failure
        }
    }

    // MARK: - Private
}
