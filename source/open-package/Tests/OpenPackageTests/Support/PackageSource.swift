//
//  PackageSource.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation

struct PackageSource {
    // MARK: - Property
    /// The Swift package the runner is built from.
    let root: URL

    /// The open-package that Swift package sits inside, where the normative documents are.
    var package: URL {
        var directory = root

        while directory.path != "/" {
            if FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("manifest.toml").path
            ) {
                break
            }

            directory = directory.deletingLastPathComponent()
        }

        return directory
    }

    // MARK: - Initializer
    init() {
        var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

        // Walking up to the manifest keeps every caller independent of how deep it sits in the
        // tree. A fixed number of deletingLastPathComponent() calls points at the wrong
        // directory the moment a test file moves.
        while directory.path != "/" {
            if FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("Package.swift").path
            ) {
                break
            }

            directory = directory.deletingLastPathComponent()
        }

        self.root = directory
    }

    // MARK: - Public
    func file(_ relativePath: String) -> URL {
        root.appendingPathComponent(relativePath)
    }

    // MARK: - Private
}
