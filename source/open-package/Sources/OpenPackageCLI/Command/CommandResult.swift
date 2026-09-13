//
//  CommandResult.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import ArgumentParser

/// What one built-in produced, stated once in both forms. They are stated together rather
/// than chosen between, so a built-in cannot fill one in and leave the other empty.
struct CommandResult<Record: EnvelopeRecord> {
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
