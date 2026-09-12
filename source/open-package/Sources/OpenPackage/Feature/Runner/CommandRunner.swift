//
//  CommandRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Looks a name up in the manifest and runs the line it stands for. The working directory
/// is always the package root, so a manifest writes its paths relative to the package and
/// to nothing else.
public struct CommandRunner: Sendable {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    public init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    /// The exit status of the command. A name the manifest does not declare is refused here,
    /// so "there is no such command" comes from the package rather than from whichever
    /// surface asked.
    public func run(_ name: String, arguments: [String]) throws -> Int32 {
        try resolve(name).run(arguments)
    }

    /// The command a name stands for, read once. A surface that has to know whether a call
    /// reaches anything before it decides what else to print asks for this and then runs it.
    public func resolve(_ name: String) throws -> ResolvedCommand {
        let directory = try PackageLocator(origin: origin).package()

        guard let line = try directory.manifest().command(named: name) else {
            throw RunnerError.unknownCommand(name)
        }

        return ResolvedCommand(name: name, line: line, root: directory.root)
    }

    // MARK: - Private
}
