//
//  PackageFactoryTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import Testing

@testable import OpenPackage

@Suite("PackageFactory Tests")
struct PackageFactoryTests {
    // MARK: - Property
    private let workspace = Workspace()

    // MARK: - Initializer
    // MARK: - Test
    @Test("a created package holds the whole skeleton")
    func createsSkeleton() throws {
        // Given
        let destination = workspace.path("minted")

        // When
        let identifier = try PackageFactory().create(at: destination)

        // Then
        #expect(identifier == "minted")

        for entry in [
            PackageLayout.manifest,
            PackageLayout.readme,
            "\(PackageLayout.source)/.gitkeep",
            "\(PackageLayout.document)/.gitkeep"
        ] {
            #expect(
                FileManager.default.fileExists(atPath: destination.appendingPathComponent(entry).path),
                "expected \(entry)"
            )
        }
    }

    @Test("the skeleton it writes is a package the inspector accepts")
    func writesSoundPackage() throws {
        // Given
        let destination = workspace.path("minted")

        // When
        try PackageFactory().create(at: destination)

        // Then
        let directory = PackageDirectory(root: destination)
        let manifest = try directory.speakableManifest()

        #expect(manifest.name == "minted")
        #expect(manifest.command(named: "verify") != nil)
        #expect(PackageInspector(directory: directory, manifest: manifest).inspect().isSound)
    }

    @Test("an existing path is refused rather than written over")
    func refusesExistingPath() throws {
        // Given
        let destination = workspace.path("taken")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        // When, Then
        #expect(throws: PackageError.self) {
            try PackageFactory().create(at: destination)
        }
    }

    // MARK: - Private
}
