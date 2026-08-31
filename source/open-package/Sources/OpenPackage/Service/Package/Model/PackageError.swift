//
//  PackageError.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Why a path is not a package, or not one that can be made. What the manifest inside it
/// gets wrong is `ManifestError`, and what a runner refuses although the package is sound
/// is `RunnerError`.
public enum PackageError: Error, CustomStringConvertible, Sendable {
    case packageNotFound
    case pathExists(URL)
    case unnamedPackage(URL)

    // MARK: - Property
    public var description: String {
        switch self {
        case .packageNotFound:
            return "no open-package here. Looked for \(PackageLayout.manifest) in this directory and upward"

        case let .pathExists(url):
            return "already exists: \(url.path)"

        case let .unnamedPackage(url):
            return "cannot read a package name from: \(url.path)"
        }
    }
}
