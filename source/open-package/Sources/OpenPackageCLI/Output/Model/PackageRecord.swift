//
//  PackageRecord.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import Foundation
import OpenPackage

/// The same thing the screen shows, in the shape a caller parses rather than reads. The
/// keys are the manifest's own table names, so a reader who knows `manifest.toml` already
/// knows this. Which binary wrote it is `Envelope`'s to say.
struct PackageRecord: EnvelopeRecord {
    // MARK: - Property
    let openPackage: Compatibility?
    let package: Metadata?
    let command: [Declaration]?
    let diagnosis: Report?

    private enum CodingKeys: String, CodingKey {
        case openPackage = "open-package"
        case package
        case command
        case diagnosis
    }

    // MARK: - Initializer
    /// Absent rather than present and empty, at both levels. A caller that finds `package`
    /// missing has been told there is nothing here; one that finds it empty has to guess
    /// whether the package said nothing or nobody asked.
    ///
    /// This cannot tell a field nobody wrote from one written empty. The manifest folded
    /// those together before this saw them, and a package with either is malformed alike.
    init(manifest: Manifest?, diagnosis: Diagnosis? = nil) {
        self.openPackage = manifest.map { Compatibility(version: "\($0.requiredRunner)") }
        self.package = manifest.map {
            Metadata(
                name: Self.nilIfEmpty($0.name),
                version: Self.nilIfEmpty($0.version),
                description: Self.nilIfEmpty($0.summary),
                requires: Self.nilIfEmpty($0.requires)
            )
        }
        self.command = manifest.flatMap { manifest in
            Self.nilIfEmpty(manifest.commands.map { command in
                let name = CommandName(command.name)

                return Declaration(
                    name: command.name,
                    run: command.text,
                    conflict: name.conflict.map(Declaration.token),
                    invocation: name.conflict == nil ? nil : name.invocation
                )
            })
        }
        self.diagnosis = diagnosis.map { Report(errors: $0.errors, warnings: $0.warnings) }
    }

    // MARK: - Public
    // MARK: - Private
    /// The rule above, in one place. Written out at each field it is a rule the next field
    /// can be added without.
    private static func nilIfEmpty<Value: Collection>(_ value: Value) -> Value? {
        value.isEmpty ? nil : value
    }
}

extension PackageRecord {
    /// `[open-package]`, the one compatibility axis.
    struct Compatibility: Encodable {
        // MARK: - Property
        let version: String

        // MARK: - Initializer
        // MARK: - Public
        // MARK: - Private
    }

    /// `[package]`, what the package says it is. `name` is not an identifier here any more
    /// than it is in the manifest.
    struct Metadata: Encodable {
        // MARK: - Property
        let name: String?
        let version: String?
        let description: String?
        let requires: [String]?

        // MARK: - Initializer
        // MARK: - Public
        // MARK: - Private
    }

    /// One entry of `[command]`: the name it is called by, the line that runs, and, where
    /// the short form does not reach it, why and what to write instead. A caller that builds
    /// `open-package <name>` without reading `conflict` would send it somewhere else.
    ///
    /// `invocation` is there so that the rule for writing it stays in `CommandName` rather
    /// than being rebuilt from `conflict` by everyone who reads this.
    struct Declaration: Encodable {
        // MARK: - Property
        let name: String
        let run: String
        let conflict: String?
        let invocation: String?

        // MARK: - Initializer
        // MARK: - Public
        /// Written out here rather than taken from the case name. `Conflict` is this
        /// runner's own word for a judgement it makes; these are what a caller parses.
        /// Editing one of these strings is a change to the JSON a caller reads, and moves
        /// with `[open-package] version` rather than with a Swift rename.
        static func token(for conflict: CommandName.Conflict) -> String {
            switch conflict {
            case .reserved: return "reserved"
            case .option: return "option"
            }
        }

        // MARK: - Private
    }

    /// What `check` found. Present only when something asked it to look.
    struct Report: Encodable {
        // MARK: - Property
        let errors: [String]
        let warnings: [String]

        // MARK: - Initializer
        // MARK: - Public
        // MARK: - Private
    }
}
