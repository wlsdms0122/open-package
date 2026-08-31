//
//  PackageFactory.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Creates a package: the manifest, the README and the two branches, and nothing else.
struct PackageFactory: Sendable {
    // MARK: - Property
    // MARK: - Initializer
    // MARK: - Public
    @discardableResult
    func create(at destination: URL) throws -> String {
        let files = FileManager.default

        guard !files.fileExists(atPath: destination.path) else {
            throw PackageError.pathExists(destination)
        }

        let identifier = destination.lastPathComponent
        guard !identifier.isEmpty, identifier != ".", identifier != ".." else {
            throw PackageError.unnamedPackage(destination)
        }

        let parent = destination.deletingLastPathComponent()
        try files.createDirectory(at: parent, withIntermediateDirectories: true)

        // Built aside and moved in one step: a half-written package would refuse the retry
        // that would have completed it. The staging directory sits on the destination's own
        // volume, so the move is a rename.
        let staging = try files.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: parent,
            create: true
        )
        defer { try? files.removeItem(at: staging) }

        let package = staging.appendingPathComponent(identifier)
        try write(PackageSkeleton(identifier: identifier), into: package)
        try files.moveItem(at: package, to: destination)

        return identifier
    }

    // MARK: - Private
    private func write(_ skeleton: PackageSkeleton, into package: URL) throws {
        let files = FileManager.default

        for branch in [PackageLayout.source, PackageLayout.document] {
            let directory = package.appendingPathComponent(branch)
            try files.createDirectory(at: directory, withIntermediateDirectories: true)

            // Most version control systems do not carry an empty directory.
            files.createFile(atPath: directory.appendingPathComponent(".gitkeep").path, contents: nil)
        }

        try skeleton.manifest.write(
            to: package.appendingPathComponent(PackageLayout.manifest),
            atomically: true,
            encoding: .utf8
        )
        try skeleton.readme.write(
            to: package.appendingPathComponent(PackageLayout.readme),
            atomically: true,
            encoding: .utf8
        )
    }
}
