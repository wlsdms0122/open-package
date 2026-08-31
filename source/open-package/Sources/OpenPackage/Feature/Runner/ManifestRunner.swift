//
//  ManifestRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// What the package around a place declares, without judging any of it.
///
/// Standing outside a package and standing in one that cannot be read are different
/// answers, and this keeps them apart: nothing found is `nil`, while something found and
/// unreadable is raised. A surface that folded the two together would tell someone whose
/// manifest has a typo that they are in the wrong directory.
public struct ManifestRunner: Sendable {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    public init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    public func run() throws -> Manifest? {
        try PackageLocator(origin: origin).locate()?.speakableManifest()
    }

    // MARK: - Private
}
