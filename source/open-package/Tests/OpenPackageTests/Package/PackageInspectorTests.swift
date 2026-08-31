//
//  PackageInspectorTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import Testing

@testable import OpenPackage

@Suite("PackageInspector Tests")
struct PackageInspectorTests {
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
        #expect(!diagnosis.isSound)
        #expect(diagnosis.errors.contains { $0.contains("name") })
        #expect(diagnosis.errors.contains { $0.contains("version") })
    }

    @Test("a package that does not describe itself is said so, and is still a package")
    func warnsAboutMissingReadme() throws {
        // Given
        let root = try workspace.package("fixture", manifest: .manifest(named: "fixture"))
        try FileManager.default.removeItem(at: root.appendingPathComponent(PackageLayout.readme))

        // When
        let diagnosis = try inspect(root)

        // Then the layout is a convention, so a departure is reported without failing.
        #expect(diagnosis.isSound)
        #expect(diagnosis.warnings.contains { $0.contains(PackageLayout.readme) })
    }

    @Test("a package carrying neither source nor document is said so, and is still a package")
    func warnsAboutEmptyPackage() throws {
        // Given
        let root = try workspace.package("fixture", manifest: .manifest(named: "fixture"))
        for branch in [PackageLayout.source, PackageLayout.document] {
            try FileManager.default.removeItem(at: root.appendingPathComponent(branch))
        }

        // When
        let diagnosis = try inspect(root)

        // Then
        #expect(diagnosis.isSound)
        #expect(diagnosis.warnings.contains { $0.contains(PackageLayout.source) })
    }

    @Test("a manifest is the whole of what a package must have")
    func acceptsAPackageThatIsOnlyAManifest() throws {
        // Given a directory holding nothing but the one required file.
        let root = try workspace.package("fixture", manifest: .manifest(named: "fixture"))
        for entry in [PackageLayout.readme, PackageLayout.source, PackageLayout.document] {
            try FileManager.default.removeItem(at: root.appendingPathComponent(entry))
        }

        // When
        let diagnosis = try inspect(root)

        // Then
        #expect(diagnosis.isSound)
        #expect(diagnosis.errors.isEmpty)
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
        #expect(diagnosis.isSound, "a package is not malformed because this machine is short a tool")
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
        #expect(!(try inspect(root).isSound))
    }

    @Test("an entry outside the specification is a warning")
    func warnsAboutStrayEntry() throws {
        // Given
        let root = try workspace.package("fixture", manifest: .manifest(named: "fixture"))
        try "".write(to: root.appendingPathComponent("build.py"), atomically: true, encoding: .utf8)

        // When
        let diagnosis = try inspect(root)

        // Then
        #expect(diagnosis.isSound)
        #expect(diagnosis.warnings.contains { $0.contains("build.py") })
    }

    @Test("dotfiles and licences are allowed at the top level")
    func allowsDotfilesAndLicence() throws {
        // Given
        let root = try workspace.package("fixture", manifest: .manifest(named: "fixture"))
        for entry in [".gitignore", "LICENSE.md"] {
            try "".write(to: root.appendingPathComponent(entry), atomically: true, encoding: .utf8)
        }

        // When, Then
        #expect(try inspect(root).isClean)
    }

    @Test("what a package calls itself is not checked against the directory it is in")
    func staysSilentAboutTheDirectoryName() throws {
        // Given a name that reads like a title rather than like a path.
        let root = try workspace.package("fixture", manifest: .manifest(named: "Quite Another Name"))

        // When, Then which package this is, is where it is, so there is nothing to disagree.
        #expect(try inspect(root).isClean)
    }

    @Test(
        "which names a package spends is not the specification's business",
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
        // which words a runner has spent is that runner's fact, and CommandNameTests covers it.
        #expect(try inspect(root).isClean)
    }


    // MARK: - Private
    private func inspect(_ root: URL) throws -> Diagnosis {
        let directory = PackageDirectory(root: root)

        return PackageInspector(directory: directory, manifest: try directory.speakableManifest()).inspect()
    }
}
