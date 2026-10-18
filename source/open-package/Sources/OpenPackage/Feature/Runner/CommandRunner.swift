//
//  CommandRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Looks a name up in the manifest of the package around a place.
public struct CommandRunner: Sendable {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    public init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    public func resolve(_ name: String) throws -> ResolvedCommand {
        let directory = try PackageLocator(origin: origin).package()

        guard let line = try directory.manifest().command(named: name) else {
            throw RunnerError.unknownCommand(name)
        }

        return ResolvedCommand(name: name, line: line, root: directory.root)
    }

    // MARK: - Private
}
