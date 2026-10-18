//
//  PackageDirectory.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

struct PackageDirectory: Sendable {
    // MARK: - Property
    let root: URL

    // MARK: - Initializer
    init(root: URL) {
        self.root = root
    }

    // MARK: - Public
    func manifest() throws -> Manifest {
        try ManifestLoader(url: root.appendingPathComponent(Manifest.fileName)).load()
    }

    // MARK: - Private
}
