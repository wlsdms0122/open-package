//
//  PackageDirectory.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// A package on disk, and the manifest it declares.
struct PackageDirectory: Sendable {
    // MARK: - Property
    let root: URL

    // MARK: - Initializer
    init(root: URL) {
        self.root = root
    }

    // MARK: - Public
    /// The only way in. A runner that cannot speak for the package does nothing, so there
    /// is deliberately no ungated read here for a caller to reach for by mistake.
    func speakableManifest() throws -> Manifest {
        try ManifestLoader(url: root.appendingPathComponent(PackageLayout.manifest)).loadSpeakable()
    }

    // MARK: - Private
}
