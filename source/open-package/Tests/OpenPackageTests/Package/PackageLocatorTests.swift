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

    @Test("nowhere near a package it finds nothing rather than guessing")
    func findsNothingOutsideAPackage() {
        // Given
        let sut = PackageLocator(origin: workspace.root)

        // When, Then
        #expect(sut.locate() == nil)
    }

    // MARK: - Private
}
