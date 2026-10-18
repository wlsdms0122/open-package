//
//  ManifestRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// `nil` when no package is found; a found but broken manifest throws.
public struct ManifestRunner: Sendable {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    public init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    public func run() throws -> Manifest? {
        try PackageLocator(origin: origin).locate()?.manifest()
    }

    // MARK: - Private
}
