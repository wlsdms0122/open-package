//
//  Manifest.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// What a package declares about itself. Where it will be placed, and when to reach for
/// it, are the receiving side's knowledge and deliberately absent.
public struct Manifest: Sendable {
    // MARK: - Property
    public let requiredRunner: Version
    /// What the package calls itself. Not an identifier: which package this is, is the
    /// directory it is in, and a second copy of that in the manifest would be a fact that
    /// can drift from the one that decided it.
    public let name: String
    public let version: String
    public let summary: String
    public let requires: [String]
    public let commands: [Command]

    // MARK: - Initializer
    /// A field written as something other than a string is refused, not rendered as one.
    /// A missing field is left empty instead, because whether it had to be there is the
    /// specification's question and `check` is where it is asked.
    ///
    /// `[open-package] version` is the exception, and is read as a version here. It is the
    /// field that decides whether the rest may be read at all, so a manifest that cannot
    /// say which open-package it is written for is not one yet. A version held as text is
    /// also a version parsed again at every place that compares it.
    init(document: TOMLDocument) throws {
        guard let declared = try document.string("open-package.version") else {
            throw ManifestError.undeclaredRequirement
        }
        guard let required = Version(declared) else {
            throw ManifestError.unreadableRequirement(declared)
        }

        self.requiredRunner = required
        self.name = try document.string("package.name") ?? ""
        self.version = try document.string("package.version") ?? ""
        self.summary = try document.string("package.description") ?? ""
        self.requires = try document.strings("package.requires")
        self.commands = try document.table("command").map { entry in
            guard case let .string(text) = entry.value else {
                throw TOMLError(line: entry.line, reason: "'[command] \(entry.key)' must be a string")
            }

            return Command(name: entry.key, text: text)
        }
    }

    // MARK: - Public
    func command(named name: String) -> String? {
        commands.first { $0.name == name }?.text
    }

    // MARK: - Private
}

public extension Manifest {
    /// A command as the manifest states it: the name it is called by, and the line that
    /// runs.
    struct Command: Equatable, Sendable {
        // MARK: - Property
        public let name: String
        public let text: String

        // MARK: - Initializer
        internal init(name: String, text: String) {
            self.name = name
            self.text = text
        }

        // MARK: - Public
        // MARK: - Private
    }
}
