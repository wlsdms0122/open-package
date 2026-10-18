//
//  ManifestLoader.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Turns a file into a `Manifest`, and keeps the three ways that can fail apart. Not being
/// there, not being readable text, and not being written the way a manifest is written are
/// separate things to go and fix.
struct ManifestLoader: Sendable {
    // MARK: - Property
    private let url: URL

    // MARK: - Initializer
    init(url: URL) {
        self.url = url
    }

    // MARK: - Public
    /// Whether the file is an open-package manifest at all. One that declares the table is,
    /// however wrong the rest of it is, so the answer reads the headers and nothing else.
    func declaration() -> ManifestDeclaration {
        guard FileManager.default.fileExists(atPath: url.path) else { return .absent }
        guard let source = try? String(contentsOf: url, encoding: .utf8) else { return .unreadable }

        return TOMLParser().tableNames(in: source).contains(Manifest.declaration) ? .declared : .foreign
    }

    /// The manifest, refused unless this runner supports the version it asks for. A manifest
    /// written for a version this binary does not have would be read as something else.
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

    /// Whether the running binary supports a package asking for `required`.
    ///
    /// A newer runner reads a package written for an older one of the same major. A package
    /// asking for something this binary does not have yet is refused rather than read as far
    /// as it happens to make sense. A major apart is a different format, so the answer is no
    /// in both directions.
    static func supports(_ required: Version) -> Bool {
        required.major == Environment.version.major && required <= Environment.version
    }

    // MARK: - Private
}
