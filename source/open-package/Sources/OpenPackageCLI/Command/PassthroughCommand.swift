//
//  PassthroughCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import ArgumentParser

/// A built-in that passes the package's own output through instead of producing its own.
///
/// It holds no `OutputFormat`. A command whose arguments are captured for the package
/// cannot be given one: the parser takes everything after the name for the package, and an
/// option written before it dies as a word the parser does not know. `Passthrough` writes
/// the refusal instead, since it is the only place that can tell the runner's words from
/// the command's.
protocol PassthroughCommand: ParsableCommand {
    /// Why this command formats nothing of its own, in words a person reads.
    static var formatUnavailable: String { get }
}

extension PassthroughCommand {
    /// Unreachable: every call by this name is dispatched before the parser sees it, and
    /// the spellings that are not are ones the parser turns away itself.
    func run() throws {
        throw CallError.undispatched(Self.configuration.commandName ?? "\(Self.self)")
    }
}
