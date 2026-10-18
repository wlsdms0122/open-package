//
//  UsageWriter.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import OpenPackage

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

        // Spelled out, since a bare bracketed version reads as the package's own.
        return [
            "\(manifest.name) \(manifest.version)  (written for open-package \(manifest.requiredRunner))"
        ] + (manifest.summary.isEmpty ? [] : [manifest.summary])
    }

    private func commands() -> [String] {
        guard let manifest else { return [] }

        guard !manifest.commands.isEmpty else {
            return ["", "COMMANDS", "    (none declared)"]
        }

        // A name the short form misses shows how to reach it.
        return ["", "COMMANDS"] + manifest.commands.map { command in
            let name = CommandName(command.name)

            guard name.conflict != nil else { return row(command.name, command.text) }

            return row(command.name, "\(command.text)  (\(name.invocation))")
        }
    }

    private func builtins() -> [String] {
        ["", "BUILT IN"] + BuiltinCommand.allCases.map { row($0.rawValue, $0.summary) }
    }

    private func footer() -> [String] {
        return [""] + (invocationHint() + [
            "Use 'open-package --json' to read this as JSON.",
            "Use 'open-package --help' for the runner's options.",
            "Use 'open-package spec' for the specification."
        ]).map { "  \($0)" }
    }

    /// Uses the rows' predicate, so it never suggests a form a row says is unreachable.
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

    /// `padding(toLength:)` also truncates, so the width must fit the longest name.
    private func row(_ name: String, _ summary: String) -> String {
        guard !summary.isEmpty else { return "    \(name)" }

        let width = max(10, name.count + 1)

        return "    \(name.padding(toLength: width, withPad: " ", startingAt: 0))\(summary)"
    }
}
