//
//  BuiltinCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser

/// The names this runner answers itself, and what each of them reaches for. It is about the
/// command line rather than the format: the library offers what can be done to a package,
/// and naming those doings is the surface's own business.
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

    /// The built-in that answers this name.
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
    /// Whether this runner answers the name itself, which is the same question as whether a
    /// manifest command by that name is reachable by the short form. `help` is not a case
    /// here, since the parser owns it, but it is taken just as firmly, so the answer lives
    /// in one place.
    static func reserves(_ name: String) -> Bool {
        name == "help" || BuiltinCommand(rawValue: name) != nil
    }
}
