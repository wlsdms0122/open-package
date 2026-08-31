//
//  CreationRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Mints a package: the manifest, the README and the two branches.
public struct CreationRunner: Sendable {
    // MARK: - Property
    // MARK: - Initializer
    public init() { }

    // MARK: - Public
    /// The identifier the new package was given, which is the last component of its path.
    @discardableResult
    public func run(at destination: URL) throws -> String {
        try PackageFactory().create(at: destination)
    }

    // MARK: - Private
}
