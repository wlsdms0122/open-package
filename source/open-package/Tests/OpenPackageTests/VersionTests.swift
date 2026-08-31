//
//  VersionTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Testing

@testable import OpenPackage

@Suite("Version Tests")
struct VersionTests {
    // MARK: - Property
    // MARK: - Initializer
    // MARK: - Test
    @Test(
        "a version reads with the parts it was given and zero for the rest",
        arguments: [
            ("1", Version(major: 1)),
            ("1.2", Version(major: 1, minor: 2)),
            ("1.2.3", Version(major: 1, minor: 2, patch: 3))
        ]
    )
    func readsShortenedVersions(text: String, expected: Version) {
        // Given, When, Then
        #expect(Version(text) == expected)
    }

    @Test(
        "anything that is not a version is refused rather than guessed at",
        arguments: [
            "", "one.two", "1.2.3.4", "1..2", "-1.0.0", "1.0.0-beta", "v1.0.0",
            // Int reads these; a compatibility axis with two spellings of one number is not one axis.
            "+1.0.0", "1.+0.0", " 1.0.0"
        ]
    )
    func refusesNonVersions(text: String) {
        // Given, When, Then
        #expect(Version(text) == nil)
    }

    @Test("versions order by major, then minor, then patch")
    func ordersByPrecedence() {
        // Given, When, Then
        #expect(Version("1.0.0")! < Version("1.0.1")!)
        #expect(Version("1.9.9")! < Version("2.0.0")!)
        #expect(Version("1.2")! == Version("1.2.0")!)
    }

    // MARK: - Private
}
