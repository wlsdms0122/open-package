//
//  CreationRunnerTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import Testing

@testable import OpenPackage

@Suite("CreationRunner Tests")
struct CreationRunnerTests {
    // MARK: - Property
    private let workspace = Workspace()

    // MARK: - Initializer
    // MARK: - Test
    @Test("a created package holds its manifest and nothing else")
    func createsManifestOnly() throws {
        // Given
        let destination = workspace.path("created")

        // When
        let identifier = try CreationRunner().run(at: destination)

        // Then
        #expect(identifier == "created")

        #expect(try FileManager.default.contentsOfDirectory(atPath: destination.path) == [Manifest.fileName])
    }

    @Test("the manifest it writes is one the inspection accepts")
    func writesValidPackage() throws {
        // Given
        let destination = workspace.path("created")

        // When
        try CreationRunner().run(at: destination)

        // Then
        let inspection = try InspectionRunner(origin: destination).run()

        #expect(inspection.manifest.name == "created")
        #expect(inspection.manifest.command(named: "verify") != nil)
        #expect(inspection.diagnosis.isValid)
    }

    @Test("an existing directory becomes a package as it stands")
    func adoptsExistingDirectory() throws {
        // Given a directory that already holds something.
        let destination = workspace.path("existing")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try "".write(to: destination.appendingPathComponent("tool.py"), atomically: true, encoding: .utf8)

        // When
        try CreationRunner().run(at: destination)

        // Then
        let entries = try FileManager.default.contentsOfDirectory(atPath: destination.path).sorted()

        #expect(entries == [Manifest.fileName, "tool.py"])
    }

    @Test("a manifest already there is refused rather than written over")
    func refusesExistingManifest() throws {
        // Given
        let destination = workspace.path("taken")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try "kept".write(
            to: destination.appendingPathComponent(Manifest.fileName),
            atomically: true,
            encoding: .utf8
        )

        // When, Then
        #expect(throws: PackageError.self) {
            try CreationRunner().run(at: destination)
        }
        #expect(
            try String(contentsOf: destination.appendingPathComponent(Manifest.fileName), encoding: .utf8)
                == "kept"
        )
    }

    @Test("a file in the way is refused")
    func refusesFileAtPath() throws {
        // Given
        let destination = workspace.path("file")
        try "".write(to: destination, atomically: true, encoding: .utf8)

        // When, Then
        #expect(throws: PackageError.self) {
            try CreationRunner().run(at: destination)
        }
    }

    // MARK: - Private
}
