//
//  InspectionRunnerTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import Testing

@testable import OpenPackage

@Suite("InspectionRunner Tests")
struct InspectionRunnerTests {
    // MARK: - Property
    private let workspace = Workspace()

    // MARK: - Initializer
    // MARK: - Test
    @Test("a well formed package raises nothing")
    func acceptsWellFormedPackage() throws {
        // Given
        let root = try workspace.package("fixture", manifest: .manifest(named: "fixture"))

        // When
        let diagnosis = try inspect(root)

        // Then
        #expect(diagnosis.isClean)
    }

    @Test("missing identity fields are errors")
    func refusesMissingIdentity() throws {
        // Given
        let root = try workspace.package("fixture", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]

            [command]
            verify = "true"
            """)

        // When
        let diagnosis = try inspect(root)

        // Then
        #expect(!diagnosis.isValid)
        #expect(diagnosis.errors.contains { $0.contains("name") })
        #expect(diagnosis.errors.contains { $0.contains("version") })
    }

    @Test("how the rest of the directory is arranged is not the specification's business")
    func staysSilentAboutTheLayout() throws {
        // Given a manifest beside entries of any name, and no README.
        let root = try workspace.package("fixture", manifest: .manifest(named: "fixture"))
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("engine"),
            withIntermediateDirectories: true
        )
        try "".write(to: root.appendingPathComponent("build.py"), atomically: true, encoding: .utf8)

        // When, Then
        #expect(try inspect(root).isClean)
    }

    @Test("a required executable this machine lacks is a warning, not a malformed package")
    func warnsAboutMissingRequirement() throws {
        // Given
        let root = try workspace.package("fixture", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            name = "fixture"
            version = "0.1.0"
            requires = ["sh", "no-such-executable-anywhere"]

            [command]
            verify = "true"
            """)

        // When
        let diagnosis = try inspect(root)

        // Then
        #expect(diagnosis.isValid, "a package is not malformed because this machine is short a tool")
        #expect(diagnosis.warnings.contains { $0.contains("no-such-executable-anywhere") })
    }

    @Test(
        "a command body that runs nothing is an error, whatever the whitespace is made of",
        arguments: ["   ", "\\n", " \\t \\n "]
    )
    func refusesEmptyCommand(body: String) throws {
        // Given
        let root = try workspace.package("fixture", manifest: .manifest(
            named: "fixture",
            commands: "verify = \"\(body)\""
        ))

        // When, Then a verify that does nothing must not be able to answer yes.
        #expect(!(try inspect(root).isValid))
    }

    @Test("what a package calls itself is not checked against the directory it is in")
    func staysSilentAboutTheDirectoryName() throws {
        // Given a name that reads like a title rather than like a path.
        let root = try workspace.package("fixture", manifest: .manifest(named: "Quite Another Name"))

        // When, Then which package this is, is where it is, so there is nothing to disagree.
        #expect(try inspect(root).isClean)
    }

    @Test(
        "which names a package uses is not the specification's business",
        arguments: ["build = \"true\"", "check = \"echo mine\"", "help = \"echo mine\"", ""]
    )
    func staysSilentAboutCommandNames(commands: String) throws {
        // Given a manifest that declares no verify, or one that declares a name the runner
        // has already taken, or nothing at all.
        let root = try workspace.package("fixture", manifest: .manifest(
            named: "fixture",
            commands: commands
        ))

        // When, Then a name means what the specification says and nothing this can see, and
        // which words a runner has taken is that runner's fact, and CommandNameTests covers it.
        #expect(try inspect(root).isClean)
    }


    // MARK: - Private
    private func inspect(_ root: URL) throws -> Diagnosis {
        try InspectionRunner(origin: root).run().diagnosis
    }
}
