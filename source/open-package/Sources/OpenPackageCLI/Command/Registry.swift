//
//  Registry.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import ArgumentParser

/// Every built-in, read from the names this runner has taken. Read from `BuiltinCommand` so
/// a name added there cannot be one nothing answers, and through the protocol for each kind
/// so a command that is neither kind cannot be named at all.
enum Registry {
    static let builtins: [ParsableCommand.Type] = BuiltinCommand.allCases.map(command(for:))

    private static func command(for name: BuiltinCommand) -> ParsableCommand.Type {
        switch name {
        case .run: return passthrough(RunCommand.self)
        case .check: return formatted(CheckCommand.self)
        case .spec: return formatted(SpecCommand.self)
        case .new: return formatted(NewCommand.self)
        }
    }

    /// The two doors. A type that conforms to neither protocol is rejected by the
    /// parameter rather than by anyone remembering to check.
    private static func formatted(_ command: any FormattedCommand.Type) -> ParsableCommand.Type { command }

    private static func passthrough(_ command: any PassthroughCommand.Type) -> ParsableCommand.Type { command }
}
