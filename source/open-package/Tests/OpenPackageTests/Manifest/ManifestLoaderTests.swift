//
//  ManifestLoaderTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Testing

@testable import OpenPackage

@Suite("ManifestLoader Tests")
struct ManifestLoaderTests {
    // MARK: - Property
    // MARK: - Initializer
    // MARK: - Test
    @Test("a runner speaks for the same major up to its own version, and for nothing else")
    func speaksWithinItsOwnMajor() throws {
        // Given the cases are written against the running binary's own version. Spelling the
        // numbers out would mean editing this suite on every release, which is an edit that
        // can silently agree with whatever the gate now does.
        let running = Environment.version

        var cases: [(Version, Bool)] = [
            (running, true),
            (Version(major: running.major), true),
            (try #require(Version("\(running.major)")), true),
            (Version(major: running.major, minor: running.minor, patch: running.patch + 1), false),
            (Version(major: running.major, minor: running.minor + 1), false),
            (Version(major: running.major + 1), false)
        ]

        if running.major > 0 {
            cases.append((Version(major: running.major - 1, minor: 9), false))
        }

        // When, Then
        for (version, expected) in cases {
            #expect(ManifestLoader.speaks(version) == expected, "\(version)")
        }
    }

    // MARK: - Private
}
