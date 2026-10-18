//
//  PackageLocator.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Walks up from `origin` to the nearest `manifest.toml` that declares an open-package;
/// other `manifest.toml` files are skipped.
struct PackageLocator: Sendable {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    /// `nil` outside a package, which is not an error.
    func locate() -> PackageDirectory? {
        var directory = origin.resolvingSymlinksInPath()

        while true {
            switch declaration(in: directory) {
            case .declared, .unreadable:
                return PackageDirectory(root: directory)

            case .absent, .foreign:
                break
            }

            let parent = directory.deletingLastPathComponent()
            guard parent.path != directory.path else { return nil }

            directory = parent
        }
    }

    func package() throws -> PackageDirectory {
        guard let directory = locate() else { throw PackageError.packageNotFound }

        return directory
    }

    // MARK: - Private
    private func declaration(in directory: URL) -> ManifestDeclaration {
        ManifestLoader(url: directory.appendingPathComponent(Manifest.fileName)).declaration()
    }
}
