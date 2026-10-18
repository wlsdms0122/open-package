//
//  FormattedCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import ArgumentParser

protocol FormattedCommand: ParsableCommand {
    associatedtype Record: Encodable

    var format: OutputFormat { get }

    func execute() throws -> CommandResult<Record>
}

extension FormattedCommand {
    /// The status is thrown after writing, so a failing command still prints what it found.
    func run() throws {
        let result = try format.refusing { try execute() }

        try format.write(result.record, render: result.render)

        guard result.status == .success else { throw result.status }
    }
}
