//
//  TOMLParserTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Testing

@testable import OpenPackage

@Suite("TOMLParser Tests")
struct TOMLParserTests {
    // MARK: - Property
    private let sut = TOMLParser()

    // MARK: - Initializer
    // MARK: - Test
    @Test("keys are qualified by their table and kept in file order")
    func keepsFileOrderUnderTables() throws {
        // Given
        let source = """
            [command]
            setup = "a"
            build = "b"
            verify = "c"
            """

        // When
        let document = try sut.parse(source)

        // Then
        #expect(document.table("command").map(\.key) == ["setup", "build", "verify"])
        #expect(try document.string("command.build") == "b")
    }

    @Test("a comment after a value is not part of the value")
    func stripsTrailingComment() throws {
        // Given
        let source = """
            [package]
            version = "1.0.0"   # a note
            """

        // When
        let document = try sut.parse(source)

        // Then
        #expect(try document.string("package.version") == "1.0.0")
    }

    @Test("a hash inside a string stays in the string")
    func keepsHashInsideString() throws {
        // Given
        let source = """
            [package]
            description = "colour #ff0000"
            """

        // When
        let document = try sut.parse(source)

        // Then
        #expect(try document.string("package.description") == "colour #ff0000")
    }

    @Test("arrays of strings are read as elements")
    func readsStringArray() throws {
        // Given
        let source = """
            [package]
            requires = ["python3", "bash", "curl"]
            """

        // When
        let document = try sut.parse(source)

        // Then
        #expect(try document.strings("package.requires") == ["python3", "bash", "curl"])
    }

    @Test("integers and booleans are read as themselves")
    func readsScalars() throws {
        // Given
        let source = """
            [gate]
            retries = 3
            enabled = true
            """

        // When
        let document = try sut.parse(source)

        // Then
        #expect(document.table("gate").map(\.value) == [.integer(3), .boolean(true)])
    }

    @Test("escapes inside a string are resolved")
    func resolvesEscapes() throws {
        // Given
        let source = #"""
            [help]
            build = "say \"hi\"\nthen stop"
            """#

        // When
        let document = try sut.parse(source)

        // Then
        #expect(try document.string("help.build") == "say \"hi\"\nthen stop")
    }

    @Test("a line ending carried in from another platform does not move the line numbers")
    func countsCarriageReturnedLinesOnce() throws {
        // Given a file written with CRLF, with the mistake on the fifth line.
        let source = [
            "[package]",
            "id = \"fixture\"",
            "",
            "[command]",
            "build = open-package"
        ].joined(separator: "\r\n")

        // When, Then
        let error = #expect(throws: TOMLError.self) { try sut.parse(source) }
        #expect(error?.line == 5, "\(error?.description ?? "no error")")
    }

    @Test("a value of the wrong type is refused rather than rendered as a string")
    func refusesMistypedValues() throws {
        // Given
        let document = try sut.parse("""
            [open-package]
            version = 1

            [package]
            requires = "sh"
            """)

        // When, Then
        #expect(throws: TOMLError.self) { try document.string("open-package.version") }
        #expect(throws: TOMLError.self) { try document.strings("package.requires") }
    }

    @Test(
        "shapes the specification does not use are refused rather than half understood",
        arguments: [
            "[package]\nid = open-package",
            "[package]\nid = \"a\"\nid = \"b\"",
            "[package]\nid = \"open-package",
            "[package]\nrequires = [\"sh\", \"awk\"",
            "[package]\njust words",
            "open-package.version = \"1.0.0\"",
            "[command]\nsub.name = \"x\"",
            "[package\nid = \"a\"",
            "[]\nid = \"a\"",
            "[[command]]\nverify = \"x\"",
            "[command.nested]\nverify = \"x\"",
            "[com mand]\nverify = \"x\"",
            "[\"command\"]\nverify = \"x\"",
            "[command]\n\"verify\" = \"x\"",
            "id = \"a\"\n\n[package]\nname = \"a\""
        ]
    )
    func refusesShapesOutsideTheSubset(source: String) {
        // Given, When, Then
        #expect(throws: TOMLError.self) {
            try sut.parse(source)
        }
    }

    @Test("the reported line points at the offending line")
    func reportsLineNumber() throws {
        // Given
        let source = """
            [package]
            id = "ok"

            name = nope
            """

        // When
        let error = #expect(throws: TOMLError.self) {
            try sut.parse(source)
        }

        // Then
        #expect(error?.line == 4)
    }

    // MARK: - Private
}
