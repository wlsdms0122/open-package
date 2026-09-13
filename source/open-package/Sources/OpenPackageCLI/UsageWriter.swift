//
//  UsageWriter.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import OpenPackage

/// The screen someone sees who does not know what is inside a package. A runner standing on
/// its own still prints what it can do.
struct UsageWriter {
    // MARK: - Property
    private let manifest: Manifest?

    // MARK: - Initializer
    init(manifest: Manifest?) {
        self.manifest = manifest
    }

    // MARK: - Public
    func text() -> String {
        (heading() + commands() + builtins() + footer())
            .joined(separator: "\n")
    }

    // MARK: - Private
    private func heading() -> [String] {
        guard let manifest else {
            return [
                "open-package \(Environment.version)",
                "No package here."
            ]
        }

        // Spelled out. A bare version in brackets reads as a second version of the package
        // rather than as the open-package it was written for.
        return [
            "\(manifest.name) \(manifest.version)  (written for open-package \(manifest.requiredRunner))"
        ] + (manifest.summary.isEmpty ? [] : [manifest.summary])
    }

    private func commands() -> [String] {
        guard let manifest else { return [] }

        guard !manifest.commands.isEmpty else {
            return ["", "COMMANDS", "    (none declared)"]
        }

        // The row is the command line itself, so it cannot describe the command wrongly. A
        // name the short form misses has to say so, and say how it is reached instead.
        return ["", "COMMANDS"] + manifest.commands.map { command in
            let name = CommandName(command.name)

            guard name.conflict != nil else { return row(command.name, command.text) }

            return row(command.name, "\(command.text)  (\(name.invocation))")
        }
    }

    private func builtins() -> [String] {
        ["", "BUILT IN"] + BuiltinCommand.allCases.map { row($0.rawValue, $0.summary) }
    }

    /// Where someone goes next, one runnable line each. Nothing else on the screen states
    /// that a command in the list above is reached by putting `open-package` in front of it.
    private func footer() -> [String] {
        // The JSON line is unconditional. A caller standing outside a package is asking a
        // machine question too.
        return [""] + (invocationHint() + [
            "Use 'open-package --json' to read this as JSON.",
            "Use 'open-package --help' for the runner's options.",
            "Use 'open-package spec' for the specification."
        ]).map { "  \($0)" }
    }

    /// Which way in to name, judged by the same predicate the rows above are marked with.
    /// Judged any other way, this line can tell a package to type the one form the row right
    /// above says will not reach it.
    private func invocationHint() -> [String] {
        guard let manifest else {
            return ["Use 'open-package new <path>' to start a package."]
        }
        guard let first = manifest.commands.first else { return [] }

        guard !manifest.commands.contains(where: { CommandName($0.name).isReachable }) else {
            return ["Use 'open-package <command>' to run one of this package's commands."]
        }

        return ["Use 'open-package \(CommandName(first.name).invocation)' to run one of this "
            + "package's commands."]
    }

    /// padding(toLength:) truncates as readily as it pads, so the width has to clear the
    /// longest name rather than assume one.
    private func row(_ name: String, _ summary: String) -> String {
        guard !summary.isEmpty else { return "    \(name)" }

        let width = max(10, name.count + 1)

        return "    \(name.padding(toLength: width, withPad: " ", startingAt: 0))\(summary)"
    }
}
