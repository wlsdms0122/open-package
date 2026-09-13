//
//  FormattedCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import ArgumentParser

/// A built-in whose output the runner writes itself. The command states its result and
/// `OutputFormat` writes it, so which form goes out has one owner rather than one per
/// command.
protocol FormattedCommand: ParsableCommand {
    associatedtype Record: EnvelopeRecord

    var format: OutputFormat { get }

    /// What this built-in produces, and what it leaves with.
    func execute() throws -> CommandResult<Record>
}

extension FormattedCommand {
    /// The only way out of a built-in. The status is read after the result is written, so
    /// that a failing command still writes what it found.
    func run() throws {
        let result = try format.refusing { try execute() }

        try format.write(result.record, render: result.render)

        guard result.status == .success else { throw result.status }
    }
}
