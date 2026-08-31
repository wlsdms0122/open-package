//
//  CommandLineTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import Testing

@testable import OpenPackage
@testable import OpenPackageCLI

/// The contract a package sees: a real binary, real directories, real exit codes. The unit
/// suites cover what the runner reads and judges; this covers what it does.
@Suite("CommandLine Tests")
struct CommandLineTests {
    // MARK: - Property
    private let workspace = Workspace()
    private let cli = CLIRunner()

    // MARK: - Initializer
    // MARK: - Test
    @Test("a well formed package passes check")
    func passesCheck() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))

        // When
        let result = run(package, "check")

        // Then
        #expect(result.status == 0, "\(result.output)")
    }

    @Test("the version line names the runner")
    func reportsVersion() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))

        // When
        let result = run(package, "--version")

        // Then
        #expect(result.standardOutput.contains("\(Environment.version)"), "\(result.output)")
    }

    @Test("no argument lists what the package declares, and what each name runs")
    func listsDeclaredCommands() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "greet = \"echo hello\"\nverify = \"true\""
        ))

        // When
        let result = run(package)

        // Then
        #expect(result.standardOutput.contains("greet"), "\(result.output)")
        #expect(result.standardOutput.contains("echo hello"), "\(result.output)")
        #expect(result.standardOutput.contains(BuiltinCommand.new.rawValue), "\(result.output)")
    }

    @Test("the manual explains how package commands are reached")
    func documentsPassthrough() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))

        // When
        let result = run(package, "--help")

        // Then
        #expect(result.standardOutput.contains("PACKAGE COMMANDS"), "\(result.output)")
        #expect(result.standardOutput.contains("WHICH PACKAGE"), "\(result.output)")
    }

    @Test("arguments reach the command, and a space keeps them together")
    func passesArgumentsThrough() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "echo = \"echo\"\nverify = \"true\""
        ))

        // When
        let plain = run(package, "echo", "hello", "world")
        let spaced = run(package, "echo", "a b", "c")

        // Then
        #expect(plain.standardOutput == "hello world\n", "\(plain.output)")
        #expect(spaced.standardOutput == "a b c\n", "\(spaced.output)")
    }

    @Test("a command that places \"$@\" itself decides where the arguments land")
    func honoursExplicitArgumentPlacement() throws {
        // Given a line whose tail is not where arguments belong.
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: #"""
                tail = "echo one; echo two"
                placed = "echo \"$@\"; echo two"
                verify = "true"
                """#
        ))

        // When
        let appended = run(package, "tail", "given")
        let placed = run(package, "placed", "given")

        // Then
        #expect(appended.standardOutput == "one\ntwo given\n", "\(appended.output)")
        #expect(placed.standardOutput == "given\ntwo\n", "\(placed.output)")
    }

    @Test("a manifest that cannot be read says so rather than reporting no package")
    func reportsAnUnreadableManifest() throws {
        // Given
        let package = try bundled("broken", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package
            name = "broken"
            """)

        // When
        let result = run(package)

        // Then
        #expect(result.status != 0, "\(result.output)")
        #expect(!result.output.contains("No package here"), "\(result.output)")
        #expect(result.output.contains("line 4"), "\(result.output)")
    }

    @Test("commands run from the package root even when called from inside it")
    func runsFromThePackageRoot() throws {
        // Given
        let package = try bundled("located", manifest: .manifest(
            named: "located",
            commands: "where = \"pwd\"\nverify = \"true\""
        ))
        let deep = package.appendingPathComponent("source/nested")
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)

        // When
        let result = cli.run(["where"], from: deep)

        // Then
        let reported = URL(
            fileURLWithPath: result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        #expect(canonical(reported) == canonical(package), "\(result.output)")
    }

    @Test("the command's exit code is the runner's exit code")
    func propagatesExitCode() throws {
        // Given
        let package = try bundled("exits", manifest: .manifest(
            named: "exits",
            commands: "verify = \"exit 3\""
        ))

        // When
        let result = run(package, "verify")

        // Then
        #expect(result.status == 3, "\(result.output)")
    }

    @Test("an unknown command fails")
    func refusesUnknownCommand() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))

        // When
        let result = run(package, "nope")

        // Then
        #expect(result.status != 0, "\(result.output)")
    }

    @Test("run reaches a name the runner would otherwise answer first")
    func runReachesAShadowedName() throws {
        // Given a package that spends a word this runner has taken.
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "check = \"echo the package answered\""
        ))

        // When
        let short = run(package, "check")
        let long = run(package, "run", "check")

        // Then the short form is the runner's, and nothing a manifest states is out of reach.
        // The inspection it runs reports the spent name, which is how a package finds out.
        #expect(!short.standardOutput.contains("the package answered"), "\(short.output)")
        #expect(short.output.contains(BuiltinCommand.run.rawValue), "\(short.output)")
        #expect(long.standardOutput.contains("the package answered"), "\(long.output)")
    }

    @Test("run leaves the arguments to the command, including ones shaped like options")
    func runPassesOptionsThrough() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "greet = \"echo\""
        ))

        // When
        let result = run(package, "run", "greet", "--help")

        // Then `--help` was addressed past the runner, so the runner did not answer it.
        #expect(result.standardOutput.contains("--help"), "\(result.output)")
        #expect(!result.standardOutput.contains("OVERVIEW"), "\(result.output)")
    }

    @Test("run carries the command's exit code out, the way the short form does")
    func runReportsTheCommandStatus() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "verify = \"exit 3\""
        ))

        // When
        let result = run(package, "run", "verify")

        // Then
        #expect(result.status == 3, "\(result.output)")
    }

    @Test("a package this runner cannot speak for runs nothing")
    func refusesUnspeakablePackages() throws {
        // Given the cases are written against the running binary's own version. Spelling
        // them out would mean editing this suite on every release, and an edit made to get
        // back to green can agree with whatever the gate now does.
        let running = Environment.version
        let unspeakable = [
            "\(running.major + 97).0.0",
            "\(running.major + 1).0.0",
            "\(running.major).\(running.minor + 1).0"
        ]

        for required in unspeakable {
            // Given
            let package = try bundled("elsewhere-\(required)", manifest: .manifest(
                named: "elsewhere",
                requiring: required
            ))

            // When
            let result = run(package, "verify")

            // Then
            #expect(result.status != 0, "\(required): \(result.output)")
        }
    }

    @Test("a package written for this major's first version still runs")
    func speaksForOlderPackages() throws {
        // Given
        let package = try bundled("older", manifest: .manifest(
            named: "older",
            requiring: "\(Environment.version.major).0.0",
            commands: "verify = \"true\""
        ))

        // When
        let result = run(package, "verify")

        // Then
        #expect(result.status == 0, "\(result.output)")
    }

    @Test("a manifest that states no open-package version is refused")
    func refusesUndeclaredRequirement() throws {
        // Given
        let package = try bundled("silent", manifest: """
            [package]
            name = "silent"
            version = "0.1.0"

            [command]
            verify = "true"
            """)

        // When
        let result = run(package, "verify")

        // Then
        #expect(result.status != 0, "\(result.output)")
    }

    @Test("a malformed manifest is refused with the line that caused it")
    func reportsManifestLine() throws {
        // Given
        let package = try bundled("broken", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            id = broken
            """)

        // When
        let result = run(package, "check")

        // Then
        #expect(result.status != 0, "\(result.output)")
        #expect(result.output.contains("line 5"), "\(result.output)")
    }

    @Test("a runner standing on its own explains itself and mints the first package")
    func worksWithoutAPackage() throws {
        // Given
        let lone = try loneRunner()
        let minted = workspace.path("minted-by-a-lone-runner")

        // When
        let usage = cli.run([], from: workspace.root, runner: lone)
        let specification = cli.run([BuiltinCommand.spec.rawValue], from: workspace.root, runner: lone)
        let created = cli.run([BuiltinCommand.new.rawValue, minted.path], from: workspace.root, runner: lone)
        let check = cli.run([BuiltinCommand.check.rawValue], from: workspace.root, runner: lone)

        // Then
        #expect(usage.standardOutput.contains("No package here"), "\(usage.output)")
        #expect(specification.status == 0, "\(specification.output)")
        #expect(created.status == 0, "\(created.output)")
        #expect(check.status != 0, "check has nothing to check and should say so")
    }

    @Test("a package it mints passes check at once and fails verify until one is written")
    func mintsSoundButUnfinishedPackages() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))
        let minted = workspace.path("minted")

        // When
        let created = run(package, BuiltinCommand.new.rawValue, minted.path)
        let check = cli.run(["check"], from: minted)
        let verify = cli.run(["verify"], from: minted)
        let again = run(package, BuiltinCommand.new.rawValue, minted.path)

        // Then
        #expect(created.status == 0, "\(created.output)")
        #expect(check.status == 0, "\(check.output)")
        #expect(verify.status != 0, "an unwritten verify must not pass")
        #expect(again.status != 0, "an existing path must be refused")

    }

    // MARK: - Private
    private func bundled(_ name: String, manifest: String) throws -> URL {
        guard let binary = cli.binary else {
            Issue.record("the CLI binary was not built, and this suite drives the real executable")
            throw CLIRunner.Missing()
        }

        return try workspace.package(name, manifest: manifest)
    }

    private func loneRunner() throws -> URL {
        guard let binary = cli.binary else {
            Issue.record("the CLI binary was not built, and this suite drives the real executable")
            throw CLIRunner.Missing()
        }

        let lone = workspace.path("lone-runner")
        try? FileManager.default.removeItem(at: lone)
        try FileManager.default.copyItem(at: binary, to: lone)

        return lone
    }

    /// The temporary directory reaches the same place by two names, so compare what the file
    /// system resolves rather than what each side happens to spell.
    private func canonical(_ url: URL) -> String {
        guard let resolved = realpath(url.path, nil) else { return url.path }
        defer { free(resolved) }

        return String(cString: resolved)
    }

    /// Runs the built binary, standing inside the given package.
    private func run(_ package: URL, _ arguments: String...) -> CLIRunner.Result {
        cli.run(arguments, from: package)
    }
}
