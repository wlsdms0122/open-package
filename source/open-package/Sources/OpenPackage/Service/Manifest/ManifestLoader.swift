//
//  ManifestLoader.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

struct ManifestLoader: Sendable {
    // MARK: - Property
    private let url: URL

    // MARK: - Initializer
    init(url: URL) {
        self.url = url
    }

    // MARK: - Public
    /// Reads headers only, so a file that declares the table counts however broken the rest is.
    func declaration() -> ManifestDeclaration {
        guard FileManager.default.fileExists(atPath: url.path) else { return .absent }
        guard let source = try? String(contentsOf: url, encoding: .utf8) else { return .unreadable }

        return TOMLParser().tableNames(in: source).contains(Manifest.declaration) ? .declared : .foreign
    }

    func load() throws -> Manifest {
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ManifestError.unreadable(url, reason: error.localizedDescription)
        }

        let manifest: Manifest
        do {
            manifest = try Manifest(document: try TOMLParser().parse(source))
        } catch let error as TOMLError {
            throw ManifestError.malformed(error)
        }

        guard Self.supports(manifest.requiredRunner) else {
            throw ManifestError.unsupportedRunnerVersion(required: manifest.requiredRunner)
        }

        return manifest
    }

    static func supports(_ required: Version) -> Bool {
        required.major == Environment.version.major && required <= Environment.version
    }

    // MARK: - Private
}
