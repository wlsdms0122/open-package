//
//  Workspace.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
@testable import OpenPackage

/// A scratch directory holding packages built for one test. It owns the directory, so the
/// directory goes when it does. The suite copies a runner into every package it builds,
/// and a development loop would otherwise pile those copies up.
final class Workspace {
    // MARK: - Property
    let root: URL

    // MARK: - Initializer
    init() {
        self.root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("open-package-tests")
            .appendingPathComponent(UUID().uuidString)

        // Nothing is written yet, and everything that writes creates the path it needs and
        // throws when it cannot. Failing here would only move the same report earlier.
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    // MARK: - Public
    func path(_ name: String) -> URL {
        root.appendingPathComponent(name)
    }

    /// Every step throws. A fixture that half fails silently lets "this must be missing"
    /// pass for a reason the test never meant, and a broken harness should say so loudly.
    @discardableResult
    func package(_ name: String, manifest: String) throws -> URL {
        let root = path(name)

        for branch in [PackageLayout.source, PackageLayout.document] {
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(branch),
                withIntermediateDirectories: true
            )
        }

        try manifest.write(
            to: root.appendingPathComponent(PackageLayout.manifest),
            atomically: true,
            encoding: .utf8
        )
        try "# \(name)\n".write(
            to: root.appendingPathComponent(PackageLayout.readme),
            atomically: true,
            encoding: .utf8
        )

        return root
    }

    // MARK: - Private
    deinit {
        try? FileManager.default.removeItem(at: root)
    }
}

extension String {
    static func manifest(
        named name: String,
        requiring runner: String = "\(Environment.version)",
        commands: String = "verify = \"true\""
    ) -> String {
        """
        [open-package]
        version = "\(runner)"

        [package]
        name = "\(name)"
        version = "0.1.0"

        [command]
        \(commands)
        """
    }
}
