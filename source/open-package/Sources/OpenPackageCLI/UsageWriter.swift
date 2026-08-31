//
//  UsageWriter.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import OpenPackage

/// The screen someone sees who does not know what is inside a package. A runner standing
/// on its own still answers with what it can do.
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
                "No package here. 'open-package new <path>' starts one."
            ]
        }

        return [
            "\(manifest.name) \(manifest.version)  (open-package \(manifest.requiredRunner))"
        ] + (manifest.summary.isEmpty ? [] : [manifest.summary])
    }

    private func commands() -> [String] {
        guard let manifest else { return [] }

        guard !manifest.commands.isEmpty else {
            return ["", "COMMANDS", "    (none declared)"]
        }

        // The listing is the one description of a command that cannot be wrong, because it is
        // the command. That only holds while a name the short form misses says so, and says
        // how it is reached instead.
        return ["", "COMMANDS"] + manifest.commands.map { command in
            guard CommandName(command.name).claim != nil else {
                return row(command.name, command.text)
            }

            return row(command.name, "\(command.text)  (run \(command.name))")
        }
    }

    private func builtins() -> [String] {
        ["", "BUILT IN"] + BuiltinCommand.allCases.map { row($0.rawValue, $0.summary) }
    }

    private func footer() -> [String] {
        ["", "Run 'open-package --help' for the runner, 'open-package spec' for the specification."]
    }

    /// padding(toLength:) truncates as readily as it pads, so the width has to clear the
    /// longest name rather than assume one.
    private func row(_ name: String, _ summary: String) -> String {
        guard !summary.isEmpty else { return "    \(name)" }

        let width = max(10, name.count + 1)

        return "    \(name.padding(toLength: width, withPad: " ", startingAt: 0))\(summary)"
    }
}
