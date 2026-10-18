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
    /// Replaces the runner with the command, run from the package root. The command is then
    /// the process its caller started, so its terminal, its signals and its exit are its own.
    public func run(_ arguments: [String]) throws -> Never {
        guard FileManager.default.changeCurrentDirectoryPath(root.path) else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .ENOENT)
        }

        let argv = (["/bin/sh", "-c", script, name] + arguments).map { strdup($0) } + [nil]
        execv("/bin/sh", argv)

        throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .ENOEXEC)
    }

    // MARK: - Private
    /// Arguments are appended unless the line places `"$@"` itself, since the tail of a
    /// pipeline or sequence is not where they belong.
    private var script: String {
        line.contains("$@") ? line : "\(line) \"$@\""
    }
}
