//
//  Manifest.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

public struct Manifest: Sendable {
    // MARK: - Property
    public static let fileName = "manifest.toml"
    static let declaration = "open-package"

    public let requiredRunner: Version
    /// Not an identifier: a package's identity is its directory.
    public let name: String
    public let version: String
    public let summary: String
    public let requires: [String]
    public let commands: [Command]

    // MARK: - Initializer
    /// Missing fields are left empty for `check` to judge. `[open-package] version` is
    /// required here, since it decides whether the rest may be read.
    init(document: TOMLDocument) throws {
        guard let declared = try document.string("\(Self.declaration).version") else {
            throw ManifestError.undeclaredRunnerVersion
        }
        guard let required = Version(declared) else {
            throw ManifestError.unreadableRunnerVersion(declared)
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
