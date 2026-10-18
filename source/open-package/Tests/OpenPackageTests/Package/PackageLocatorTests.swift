//
//  PackageLocatorTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import Testing

@testable import OpenPackage

@Suite("PackageLocator Tests")
struct PackageLocatorTests {
    // MARK: - Property
    private let workspace = Workspace()

    // MARK: - Initializer
    // MARK: - Test
    @Test("the package is the one the caller is standing in, however deep")
    func walksUpFromTheWorkingDirectory() throws {
        // Given
        let package = try workspace.package("standing-in", manifest: .manifest(named: "standing-in"))
        let deep = package.appendingPathComponent("source/nested/deeper")
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)

        let sut = PackageLocator(origin: deep)

        // When
        let located = sut.locate()

        // Then
        #expect(located?.root.resolvingSymlinksInPath().path == package.resolvingSymlinksInPath().path)
    }

    @Test("a manifest.toml that does not declare an open-package is passed by")
    func walksPastAForeignManifest() throws {
        // Given a manifest of some other format nested inside a package.
        let package = try workspace.package("outer", manifest: .manifest(named: "outer"))
        let foreign = package.appendingPathComponent("vendor/tool")
        try FileManager.default.createDirectory(at: foreign, withIntermediateDirectories: true)
        try "[package]\nname = \"tool\"\n".write(
            to: foreign.appendingPathComponent(PackageLayout.manifest),
            atomically: true,
            encoding: .utf8
        )

        let sut = PackageLocator(origin: foreign)

        // When
        let located = sut.locate()

        // Then
        #expect(located?.root.resolvingSymlinksInPath().path == package.resolvingSymlinksInPath().path)
    }

    @Test("a manifest that declares an open-package is the package however malformed the rest is")
    func stopsAtADeclaredManifest() throws {
        // Given a body this subset refuses under a header that declares the package.
        let package = try workspace.package("broken", manifest: """
            [open-package]
            version = "1.0.0"

            [package
            """)

        let sut = PackageLocator(origin: package)

        // When
        let located = sut.locate()

        // Then the package is found, so what is wrong with it can be said rather than missed.
        #expect(located?.root.resolvingSymlinksInPath().path == package.resolvingSymlinksInPath().path)
    }

    @Test("a manifest that cannot be read stops the walk, so the failure is said rather than skipped")
    func stopsAtAnUnreadableManifest() throws {
        // Given bytes that are not UTF-8 inside a package.
        let package = try workspace.package("outer", manifest: .manifest(named: "outer"))
        let inner = package.appendingPathComponent("inner")
        try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: true)
        try Data([0xFF, 0xFE, 0x00]).write(to: inner.appendingPathComponent(PackageLayout.manifest))

        let sut = PackageLocator(origin: inner)

        // When
        let located = sut.locate()

        // Then
        #expect(located?.root.resolvingSymlinksInPath().path == inner.resolvingSymlinksInPath().path)
        #expect(throws: ManifestError.self) { try located?.manifest() }
    }

    @Test("nowhere near a package it finds nothing rather than guessing")
    func findsNothingOutsideAPackage() {
        // Given
        let sut = PackageLocator(origin: workspace.root)

        // When, Then
        #expect(sut.locate() == nil)
    }

    // MARK: - Private
}
