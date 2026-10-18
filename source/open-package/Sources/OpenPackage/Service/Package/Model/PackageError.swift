//
//  PackageError.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

public enum PackageError: Error, CustomStringConvertible, Sendable {
    case packageNotFound
    case pathExists(URL)
    case unnamedPackage(URL)

    // MARK: - Property
    public var description: String {
        switch self {
        case .packageNotFound:
            return """
                no open-package here. Looked in this directory and upward for a \
                \(Manifest.fileName) with an [\(Manifest.declaration)] table
                """

        case let .pathExists(url):
            return "already exists: \(url.path)"

        case let .unnamedPackage(url):
            return "cannot read a package name from: \(url.path)"
        }
    }
}
