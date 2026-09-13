//
//  ManifestRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// What the package around a place declares, without judging any of it. Nothing found is
/// `nil`, while something found and unreadable is raised. Folded together, a manifest with a
/// typo would be reported as standing in the wrong directory.
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
