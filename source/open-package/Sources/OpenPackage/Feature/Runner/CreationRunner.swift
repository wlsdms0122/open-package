//
//  CreationRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Creates a package by writing its manifest. A missing directory is made, and an existing
/// one becomes a package as it stands.
public struct CreationRunner: Sendable {
    // MARK: - Property
    // MARK: - Initializer
    public init() { }

    // MARK: - Public
    /// The name the package was given, which is the last component of its path.
    @discardableResult
    public func run(at destination: URL) throws -> String {
        let files = FileManager.default
        let manifest = destination.appendingPathComponent(Manifest.fileName)

        let name = destination.lastPathComponent
        guard !name.isEmpty, name != ".", name != ".." else {
            throw PackageError.unnamedPackage(destination)
        }

        var directoryFlag: ObjCBool = false
        if files.fileExists(atPath: destination.path, isDirectory: &directoryFlag) {
            guard directoryFlag.boolValue else { throw PackageError.pathExists(destination) }
            guard !files.fileExists(atPath: manifest.path) else { throw PackageError.pathExists(manifest) }
        }

        try files.createDirectory(at: destination, withIntermediateDirectories: true)
        try template(named: name).write(to: manifest, atomically: true, encoding: .utf8)

        return name
    }

    // MARK: - Private
    /// The declared version is the first of this major, the least a new package needs. The
    /// running version would make a runner's patch release refuse what the previous one wrote.
    private func template(named name: String) -> String {
        """
        # The specification is `open-package spec`

        [open-package]
        version = "\(Version(major: Environment.version.major))"

        [package]
        name = "\(name)"
        version = "0.1.0"
        description = ""
        requires = []

        [command]
        # Commands run from the package root, and no name means anything but this line.
        # Arguments are appended, unless the line places "$@" itself.
        verify = "! echo 'verify is not written yet' >&2"

        """
    }
}
