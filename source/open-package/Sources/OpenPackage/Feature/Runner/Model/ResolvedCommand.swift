//
//  ResolvedCommand.swift
//  OpenPackage
//
//  Created by JSilver on 9/11/26.
//

import Foundation

/// A command the manifest was found to declare, and the place it runs from. Read once and
/// carried, so a surface can ask whether a call reaches anything and then run that same
/// result. Looked up twice, the second reading could find a manifest the first did not.
public struct ResolvedCommand: Sendable {
    // MARK: - Property
    let name: String
    let line: String
    let root: URL

    // MARK: - Initializer
    init(name: String, line: String, root: URL) {
        self.name = name
        self.line = line
        self.root = root
    }

    // MARK: - Public
    /// The exit status of the command. The working directory is the package root, so a
    /// manifest writes its paths relative to the package and to nothing else.
    public func run(_ arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.currentDirectoryURL = root
        process.arguments = ["-c", script, name] + arguments

        try process.run()
        process.waitUntilExit()

        return process.terminationStatus
    }

    // MARK: - Private
    /// Appending is only right for a command that is one invocation. Where a line is a
    /// pipeline or a sequence the tail is not where the arguments belong, so a manifest that
    /// writes `"$@"` places them itself.
    private var script: String {
        line.contains("$@") ? line : "\(line) \"$@\""
    }
}
