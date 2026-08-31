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
        // Given the format spends no word on a package's own command names. A table of
        // meanings growing back into either text is the drift this catches: the runner
        // would go on ignoring it, and packages would be written to a rule nothing holds.
        let claims = ["Fixed in meaning", "COMMANDS WITH A FIXED MEANING", "reserved"]

        // When, Then
        for claim in claims {
            #expect(!(try document()).contains(claim))
            #expect(!Specification.summary.contains(claim))
        }
    }

    @Test("the summary the runner carries names every built-in the runner answers")
    func summaryNamesTheBuiltinCommands() {
        // Given, When
        let sut = Specification.summary

        // Then the summary writes the built-ins as prose, because which words this surface
        // spends is not the library's to know. This is what keeps the two from drifting.
        for builtin in BuiltinCommand.allCases {
            #expect(sut.contains(builtin.rawValue))
            #expect(sut.contains(builtin.summary))
        }
    }

    @Test("the normative document names the open-package the runner is")
    func documentNamesItsVersion() throws {
        // Given, When
        let sut = try document()

        // Then section 4 says there is one compatibility axis and no separate specification
        // number, so a document that names a version the runner never reports would be a
        // second number by another route.
        #expect(sut.contains("open-package \(Environment.version)"))
    }

    @Test("the summary the runner carries names the open-package it is a summary of")
    func summaryNamesItsVersion() {
        // Given, When
        let sut = Specification.summary

        // Then
        #expect(sut.contains("\(Environment.version)"))
    }

    @Test("the layout is the same four entries in the document, the summary and the code")
    func layoutIsTheSameEverywhere() throws {
        // Given the tree is drawn twice in prose and held once as constants, and nothing
        // compiles the drawings. An entry added to one of them and nowhere else is a
        // package told to carry something no runner will allow at its top level.
        let expected: Set<String> = [
            PackageLayout.manifest,
            PackageLayout.readme,
            "\(PackageLayout.source)/",
            "\(PackageLayout.document)/"
        ]

        // When, Then
        #expect(entries(inTreeOf: try document()) == expected)
        #expect(entries(inTreeOf: Specification.summary) == expected)
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

    /// The names drawn in a layout tree: the lines under `<package>/` that sit one level in,
    /// read down to the first blank line or fence. A continuation line is indented past the
    /// name column, which is what keeps it out.
    private func entries(inTreeOf text: String) -> Set<String> {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        guard let root = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "<package>/" })
        else { return [] }

        let column = indent(of: lines[root]) + 2

        return Set(
            lines[(root + 1)...]
                .prefix { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .prefix { $0.trimmingCharacters(in: .whitespaces) != "```" }
                .filter { indent(of: $0) == column }
                .compactMap { $0.split(separator: " ").first.map(String.init) }
        )
    }

    private func indent(of line: String) -> Int {
        line.prefix { $0 == " " }.count
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
