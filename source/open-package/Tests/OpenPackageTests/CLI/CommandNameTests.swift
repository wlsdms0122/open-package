//
//  CommandNameTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Testing

@testable import OpenPackage
@testable import OpenPackageCLI

/// Which names are already spent is the command line's knowledge, not the format's, so it
/// is judged here. A package may still declare such a name, since nothing stops it, and the
/// point of the judgement is that it is told.
@Suite("CommandName Tests")
struct CommandNameTests {
    // MARK: - Property
    // MARK: - Initializer
    // MARK: - Test
    @Test("a name the runner answers itself can never reach the package", arguments: ["check", "spec", "new", "help"])
    func claimsRunnerName(name: String) {
        // Given, When
        let sut = CommandName(name)

        // Then
        #expect(sut.claim == .runner)
        #expect(!sut.isRunnable)
    }

    @Test("a name shaped like an option reaches the parser, not the package", arguments: ["-f", "--fast"])
    func claimsOptionShapedName(name: String) {
        // Given, When
        let sut = CommandName(name)

        // Then
        #expect(sut.claim == .option)
    }

    @Test("every other name is the package's own", arguments: ["build", "verify", "bake", "checked"])
    func leavesOtherNamesAlone(name: String) {
        // Given, When
        let sut = CommandName(name)

        // Then
        #expect(sut.claim == nil)
        #expect(sut.isRunnable)
    }

    @Test("a manifest declaring a spent name is reported by name", arguments: ["check", "--fast"])
    func reportsSpentNameInManifest(name: String) throws {
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
        let claims = CommandName.claims(in: sut)

        // Then
        #expect(claims.count == 1)
        #expect(claims.contains { $0.contains("[command] \(name)") })
    }
}
