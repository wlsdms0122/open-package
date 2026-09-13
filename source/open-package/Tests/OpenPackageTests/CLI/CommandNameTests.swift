//
//  CommandNameTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Testing

@testable import OpenPackage
@testable import OpenPackageCLI

/// Which names are already reserved is the command line's knowledge, not the format's, so it
/// is judged here. A package may still declare such a name, since nothing stops it, and the
/// point of the judgement is that it is told.
@Suite("CommandName Tests")
struct CommandNameTests {
    // MARK: - Property
    // MARK: - Initializer
    // MARK: - Test
    @Test("a name the runner answers itself can never reach the package", arguments: ["check", "spec", "new", "help"])
    func reservesRunnerName(name: String) {
        // Given, When
        let sut = CommandName(name)

        // Then
        #expect(sut.conflict == .reserved)
        #expect(!sut.isReachable)
    }

    @Test("a name shaped like an option reaches the parser, not the package", arguments: ["-f", "--fast"])
    func conflictsWithOptionShapedName(name: String) {
        // Given, When
        let sut = CommandName(name)

        // Then
        #expect(sut.conflict == .option)
    }

    @Test("every other name is the package's own", arguments: ["build", "verify", "bake", "checked"])
    func leavesOtherNamesAlone(name: String) {
        // Given, When
        let sut = CommandName(name)

        // Then
        #expect(sut.conflict == nil)
        #expect(sut.isReachable)
    }

    @Test("a manifest declaring a reserved name is reported by name", arguments: ["check", "--fast"])
    func reportsConflictingNameInManifest(name: String) throws {
        // Given
        let document = try TOMLParser().parse("""
            [open-package]
            version = "1.0.0"

            [command]
            \(name) = "echo mine"
            verify = "true"
            """)
        let sut = try Manifest(document: document)

        // When
        let conflicts = CommandName.conflicts(in: sut)

        // Then
        #expect(conflicts.count == 1)
        #expect(conflicts.contains { $0.contains("[command] \(name)") })
    }
}
