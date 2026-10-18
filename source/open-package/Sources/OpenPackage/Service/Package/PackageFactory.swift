//
//  PackageFactory.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Creates a package by writing its manifest. The directory is made when it is not there,
/// and taken as it stands when it is, since a manifest is all a package has to hold.
struct PackageFactory: Sendable {
    // MARK: - Property
    // MARK: - Initializer
    // MARK: - Public
    @discardableResult
    func create(at destination: URL) throws -> String {
        let files = FileManager.default
        let manifest = destination.appendingPathComponent(PackageLayout.manifest)

        let identifier = destination.lastPathComponent
        guard !identifier.isEmpty, identifier != ".", identifier != ".." else {
            throw PackageError.unnamedPackage(destination)
        }

        var directoryFlag: ObjCBool = false
        if files.fileExists(atPath: destination.path, isDirectory: &directoryFlag) {
            guard directoryFlag.boolValue else { throw PackageError.pathExists(destination) }
            guard !files.fileExists(atPath: manifest.path) else { throw PackageError.pathExists(manifest) }
        }

        try files.createDirectory(at: destination, withIntermediateDirectories: true)
        try PackageSkeleton(identifier: identifier).manifest.write(
            to: manifest,
            atomically: true,
            encoding: .utf8
        )

        return identifier
    }

    // MARK: - Private
}
