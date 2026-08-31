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
    /// The exit status of the command. A name the manifest does not declare is refused
    /// here, so that "there is no such command" is answered by the package rather than by
    /// whichever surface happened to ask.
    public func run(_ name: String, arguments: [String]) throws -> Int32 {
        let directory = try PackageLocator(origin: origin).package()
        let manifest = try directory.speakableManifest()

        guard let command = manifest.command(named: name) else {
            throw RunnerError.unknownCommand(name)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.currentDirectoryURL = directory.root
        process.arguments = ["-c", script(for: command), name] + arguments

        try process.run()
        process.waitUntilExit()

        return process.terminationStatus
    }

    // MARK: - Private
    /// Appending the arguments is only right for a command that is one invocation. Where a
    /// line is a pipeline or a sequence, the tail is not where they belong, so a manifest
    /// that writes `"$@"` itself decides, and keeps that decision visible in the listing.
    private func script(for command: String) -> String {
        command.contains("$@") ? command : "\(command) \"$@\""
    }
}
