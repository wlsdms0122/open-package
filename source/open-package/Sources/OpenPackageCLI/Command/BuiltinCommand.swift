//
//  BuiltinCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser

enum BuiltinCommand: String, CaseIterable, Sendable {
    case run
    case check
    case spec
    case new

    // MARK: - Property
    var summary: String {
        switch self {
        case .run:
            return "Run one of the package's own commands by name"

        case .check:
            return "Inspect the manifest"

        case .spec:
            return "Print the specification"

        case .new:
            return "Create a package"
        }
    }

    var command: ParsableCommand.Type {
        switch self {
        case .run:
            return RunCommand.self

        case .check:
            return CheckCommand.self

        case .spec:
            return SpecCommand.self

        case .new:
            return NewCommand.self
        }
    }

    // MARK: - Public
    /// `help` is reserved too, though the parser owns it.
    static func reserves(_ name: String) -> Bool {
        name == "help" || BuiltinCommand(rawValue: name) != nil
    }
}
