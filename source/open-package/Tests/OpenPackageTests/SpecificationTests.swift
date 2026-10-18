//
//  SpecificationTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import Testing

@testable import OpenPackage
@testable import OpenPackageCLI

/// The normative document and the runner are two statements of the same vocabulary, and
/// nothing compiles the first. This is what keeps them from drifting apart: a command
/// named in one and absent from the other is how the document quietly stops being true.
@Suite("Specification Tests")
struct SpecificationTests {
    // MARK: - Property
    private let source = PackageSource()

    // MARK: - Initializer
    // MARK: - Test
    @Test("the normative document names exactly the built-in commands the runner has")
    func documentNamesTheBuiltinCommands() throws {
        // Given
        let sut = try document()

        // When
        let named = names(inTableUnder: "### Built-in", of: sut)

        // Then
        #expect(named == Set(BuiltinCommand.allCases.map(\.rawValue)))
    }

    @Test("neither the document nor the summary fixes a command name")
    func nothingFixesACommandName() throws {
        // Given the format says nothing about a package's own command names. A table of
        // meanings growing back into either text is the drift this catches: the runner
        // would go on ignoring it, and packages would be written to a rule nothing holds.
        let fixings = ["Fixed in meaning", "COMMANDS WITH A FIXED MEANING", "reserved"]

        // When, Then
        for fixing in fixings {
            #expect(!(try document()).contains(fixing))
            #expect(!Specification.summary.contains(fixing))
        }
    }

    @Test("the summary the runner carries names every built-in the runner answers")
    func summaryNamesTheBuiltinCommands() {
        // Given, When
        let sut = Specification.summary

        // Then the summary writes the built-ins as prose, because which words this surface
        // takes is not the library's to know. This is what keeps the two from drifting.
        for builtin in BuiltinCommand.allCases {
            #expect(sut.contains(builtin.rawValue))
            #expect(sut.contains(builtin.summary))
        }
    }

    @Test("the runner is the version its own package's manifest names")
    func runnerIsItsManifestsVersion() throws {
        // Given
        let manifest = ManifestLoader(
            url: source.package.appendingPathComponent(Manifest.fileName)
        )

        // When
        let sut = try manifest.load()

        // Then
        #expect(sut.version == "\(Environment.version)")
    }

    @Test("the summary the runner carries names the open-package it is a summary of")
    func summaryNamesItsVersion() {
        // Given, When
        let sut = Specification.summary

        // Then
        #expect(sut.contains("\(Environment.version)"))
    }

    @Test("the document and the summary name the table that makes a manifest a package")
    func declarationIsTheSameEverywhere() throws {
        // Given the runner tells a package's manifest from any other manifest.toml by one
        // table, and nothing compiles the prose that tells a person which.
        let declaration = "\(Manifest.fileName) that opens an [\(Manifest.declaration)] table"

        // When, Then
        #expect(try document().replacingOccurrences(of: "`", with: "").contains(declaration))
        #expect(Specification.summary.contains(declaration))
    }

    @Test("the summary states the rule that decides where arguments land")
    func summaryStatesArgumentPlacement() {
        // Given, When
        let sut = Specification.summary

        // Then a reader who only ever sees this text still knows the exception exists.
        #expect(sut.contains("$@"))
    }

    // MARK: - Private
    private func document() throws -> String {
        try String(
            contentsOf: source.package.appendingPathComponent("document/SPEC.md"),
            encoding: .utf8
        )
    }

    /// The names in the first column of the table that follows a heading, up to the next one.
    private func names(inTableUnder heading: String, of text: String) -> Set<String> {
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        guard let start = lines.firstIndex(where: { $0.hasPrefix(heading) }) else { return [] }

        let rest = lines[(start + 1)...]
        let section = rest.prefix { !$0.hasPrefix("#") }

        return Set(section.compactMap(name(inRow:)))
    }

    private func name(inRow row: String) -> String? {
        guard row.hasPrefix("| `") else { return nil }

        return row
            .dropFirst("| `".count)
            .prefix { $0 != "`" }
            .description
    }
}
