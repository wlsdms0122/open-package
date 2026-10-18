//
//  CommandResult.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import ArgumentParser

/// Both forms are required together, so a built-in cannot fill in only one.
struct CommandResult<Record: Encodable> {
    // MARK: - Property
    let record: Record
    let status: ExitCode
    let render: () -> Void

    // MARK: - Initializer
    init(_ record: Record, status: ExitCode = .success, render: @escaping () -> Void) {
        self.record = record
        self.status = status
        self.render = render
    }

    // MARK: - Public
    // MARK: - Private
}
