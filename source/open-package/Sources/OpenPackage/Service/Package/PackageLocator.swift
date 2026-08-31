//
//  PackageLocator.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Finds the package a command is about by walking up from where it was called, the way a
/// package manager does. A package is found by where it is, not by what it is called and
/// not by an environment variable.
struct PackageLocator: Sendable {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    /// The package here, or nothing. Standing outside one is an ordinary answer, which the
    /// listing screen is written for, so it is not raised as an error.
    func locate() -> PackageDirectory? {
        var directory = origin.resolvingSymlinksInPath()

        while true {
            if holdsManifest(directory) {
                return PackageDirectory(root: directory)
            }

            let parent = directory.deletingLastPathComponent()
            guard parent.path != directory.path else { return nil }

            directory = parent
        }
    }

    /// The package here, where there being none is the caller's problem.
    func package() throws -> PackageDirectory {
        guard let directory = locate() else { throw PackageError.packageNotFound }

        return directory
    }

    // MARK: - Private
    private func holdsManifest(_ directory: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: directory.appendingPathComponent(PackageLayout.manifest).path
        )
    }
}
