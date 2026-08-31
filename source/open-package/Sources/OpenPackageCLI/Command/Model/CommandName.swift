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
/// A claimed name is not a lost one. `run` reaches any name the manifest states, so what is
/// at stake here is only which of the two ways of writing it arrives.
struct CommandName: Equatable, Sendable {
    // MARK: - Property
    let text: String

    var claim: Claim? {
        if text.hasPrefix("-") { return .option }
        if BuiltinCommand.shadows(text) { return .runner }

        return nil
    }

    var isRunnable: Bool { claim == nil }

    // MARK: - Initializer
    init(_ text: String) {
        self.text = text
    }

    // MARK: - Public
    /// What the specification cannot say and this surface can: which of a package's own
    /// command names this runner has already spent. Added to an inspection rather than
    /// produced by one, because the answer changes with the surface and not with the
    /// package.
    static func claims(in manifest: Manifest) -> [String] {
        manifest.commands.compactMap { command in
            guard let claim = CommandName(command.name).claim else { return nil }

            return "[command] \(command.name) is \(claim); "
                + "reach it with '\(BuiltinCommand.run.rawValue) \(command.name)'"
        }
    }

    // MARK: - Private
}

extension CommandName {
    enum Claim: CustomStringConvertible, Sendable {
        case runner
        case option

        var description: String {
            switch self {
            case .runner: return "a name the runner answers first"
            case .option: return "read as an option to the runner, not as a command name"
            }
        }
    }
}
