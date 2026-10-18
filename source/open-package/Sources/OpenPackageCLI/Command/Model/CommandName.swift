//
//  CommandName.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import OpenPackage

/// The one predicate shared by passthrough, the listing and `check`, so they cannot disagree.
struct CommandName: Equatable, Sendable {
    // MARK: - Property
    let text: String

    var conflict: Conflict? {
        if text.hasPrefix("-") { return .option }
        if BuiltinCommand.reserves(text) { return .reserved }

        return nil
    }

    var isReachable: Bool { conflict == nil }

    /// Option-shaped names need `--` after `run`.
    var invocation: String {
        switch conflict {
        case .option: return "\(BuiltinCommand.run.rawValue) -- \(text)"
        case .reserved, .none: return "\(BuiltinCommand.run.rawValue) \(text)"
        }
    }

    // MARK: - Initializer
    init(_ text: String) {
        self.text = text
    }

    // MARK: - Public
    /// Lives in the CLI because conflicts depend on this runner, not on the package.
    static func conflicts(in manifest: Manifest) -> [String] {
        manifest.commands.compactMap { command in
            guard let conflict = CommandName(command.name).conflict else { return nil }

            return "[command] \(command.name) is \(conflict); "
                + "reach it with '\(CommandName(command.name).invocation)'"
        }
    }

    // MARK: - Private
}

extension CommandName {
    enum Conflict: CustomStringConvertible, Sendable {
        case reserved
        case option

        var description: String {
            switch self {
            case .reserved: return "a name the runner answers first"
            case .option: return "read as an option to the runner, not as a command name"
            }
        }
    }
}
