//
//  CommandName.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import OpenPackage

/// A name as a manifest wrote it, judged against what this command line has already taken.
///
/// One predicate, three readers: what the short form passes through to the package, what the
/// listing prints beside a name, and what `check` reports. Were they to answer differently, a
/// package could list a command the short form silently misses and be told nothing.
///
/// A name in conflict is not a lost one. `run` reaches any name the manifest states, so what
/// is at stake here is only which of the two ways of writing it arrives.
struct CommandName: Equatable, Sendable {
    // MARK: - Property
    let text: String

    var conflict: Conflict? {
        if text.hasPrefix("-") { return .option }
        if BuiltinCommand.reserves(text) { return .reserved }

        return nil
    }

    /// Whether the short form reaches this name.
    var isReachable: Bool { conflict == nil }

    /// How to call this name, for a listing to print and for `check` to advise. A name the
    /// runner reads as an option needs the terminator as well, since after `run` a word
    /// shaped like an option is one until `--` says otherwise.
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
    /// What the specification cannot say and this surface can: which of a package's own
    /// command names collide with what this runner has already taken. Added to an inspection
    /// rather than produced by one, because the answer changes with the surface and not with
    /// the package.
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
    /// Why the short form does not reach a name: the runner has reserved it, or the parser
    /// reads it as an option before it can be a name at all.
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
