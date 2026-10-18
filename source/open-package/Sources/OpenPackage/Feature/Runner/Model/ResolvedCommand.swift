//
//  ResolvedCommand.swift
//  OpenPackage
//
//  Created by JSilver on 9/11/26.
//

import Foundation

/// Resolved once and then run, so the manifest is not read twice.
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
    /// Runs from the package root and returns the exit status.
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
    /// Arguments are appended unless the line places `"$@"` itself, since the tail of a
    /// pipeline or sequence is not where they belong.
    private var script: String {
        line.contains("$@") ? line : "\(line) \"$@\""
    }
}
