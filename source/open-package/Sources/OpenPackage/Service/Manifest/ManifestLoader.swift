//
//  ManifestLoader.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Turns a file into a `Manifest`, and is where the three ways that can fail are kept
/// apart. Not being there, not being readable text, and not being written the way a
/// manifest is written are separate things to go and fix, and a loader that answered all
/// three the same way would send someone looking in the wrong place.
struct ManifestLoader: Sendable {
    // MARK: - Property
    private let url: URL

    // MARK: - Initializer
    init(url: URL) {
        self.url = url
    }

    // MARK: - Public
    func load() throws -> Manifest {
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ManifestError.unreadable(url, reason: error.localizedDescription)
        }

        do {
            return try Manifest(document: try TOMLParser().parse(source))
        } catch let error as TOMLError {
            throw ManifestError.malformed(error)
        }
    }

    /// The same, refused unless this runner can speak for what it asks. Reading a manifest
    /// written for a version this binary does not have quietly does something other than
    /// what it says, so the gate is here rather than at whoever asked. An alternative that
    /// depends on remembering is one that eventually forgets.
    func loadSpeakable() throws -> Manifest {
        let manifest = try load()

        guard Self.speaks(manifest.requiredRunner) else {
            throw ManifestError.unspeakableRequirement(required: manifest.requiredRunner)
        }

        return manifest
    }

    /// Whether the running binary can speak for a package asking for `required`.
    ///
    /// A newer runner reads a package written for an older one of the same major. A package
    /// asking for something the running binary does not have yet is refused rather than read
    /// as far as it happens to make sense. A major apart is a different format, so the
    /// answer is no in both directions.
    ///
    /// The rule is the specification's, not the process's, so it sits beside the field it
    /// judges. What the binary knows about itself is only its own version.
    static func speaks(_ required: Version) -> Bool {
        required.major == Environment.version.major && required <= Environment.version
    }

    // MARK: - Private
}
