//
//  PackageRecord.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import Foundation
import OpenPackage

/// Keys mirror the manifest's table names.
struct PackageRecord: Encodable {
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
    /// Empty values are omitted rather than encoded empty, at both levels.
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
    private static func nilIfEmpty<Value: Collection>(_ value: Value) -> Value? {
        value.isEmpty ? nil : value
    }
}

extension PackageRecord {
    struct Compatibility: Encodable {
        // MARK: - Property
        let version: String

        // MARK: - Initializer
        // MARK: - Public
        // MARK: - Private
    }

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

    /// `conflict` and `invocation` are set only when the short form does not reach the name.
    struct Declaration: Encodable {
        // MARK: - Property
        let name: String
        let run: String
        let conflict: String?
        let invocation: String?

        // MARK: - Initializer
        // MARK: - Public
        /// Spelled out, not derived from case names: these strings are JSON a caller parses.
        static func token(for conflict: CommandName.Conflict) -> String {
            switch conflict {
            case .reserved: return "reserved"
            case .option: return "option"
            }
        }

        // MARK: - Private
    }

    /// Present only for `check`.
    struct Report: Encodable {
        // MARK: - Property
        let errors: [String]
        let warnings: [String]

        // MARK: - Initializer
        // MARK: - Public
        // MARK: - Private
    }
}
