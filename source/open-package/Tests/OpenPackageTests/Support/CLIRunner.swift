//
//  CLIRunner.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Drives the real executable. The contract this specification makes is about a binary
/// sitting in a directory, so the suite that guards it has to run that binary.
struct CLIRunner {
    struct Missing: Error { }

    struct Result {
        // MARK: - Property
        let status: Int32
        let standardOutput: String
        let standardError: String

        var output: String { standardOutput + standardError }

        // MARK: - Initializer
        // MARK: - Public
        // MARK: - Private
    }

    // MARK: - Property
    // SwiftPM names the built artifact after the executable product, so this literal is the
    // one place the harness can drift out of sync with Package.swift.
    static let product = "OpenPackage"

    private let candidates: [URL]

    var binary: URL? {
        candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    // MARK: - Initializer
    init(source: PackageSource = PackageSource()) {
        self.candidates = ["debug", "release"].map {
            source.file(".build/\($0)/\(Self.product)")
        }
    }

    // MARK: - Public
    @discardableResult
    func run(
        _ arguments: [String],
        from directory: URL? = nil,
        runner: URL? = nil,
        environment: [String: String] = [:]
    ) -> Result {
        guard let executable = runner ?? binary else {
            return Result(
                status: -1,
                standardOutput: "",
                standardError: """
                    harness: the CLI binary was not found, and this suite drives the real \
                    executable, so this is a broken harness rather than a product failure.
                    """
            )
        }

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory ?? URL(fileURLWithPath: "/")
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, given in given }

        // Captured through files rather than pipes. A pipe holds about 64 KB, so whichever
        // stream is read second can fill and block the child while the harness waits on the
        // first, and draining both at once would mean blocking a thread the test runner
        // needs. A file has no such limit and needs no second thread.
        let capture = Capture()
        defer { capture.remove() }

        process.standardOutput = capture.output
        process.standardError = capture.error

        do {
            try process.run()
        } catch {
            return Result(status: -1, standardOutput: "", standardError: "harness: \(error)")
        }

        process.waitUntilExit()

        return Result(
            status: process.terminationStatus,
            standardOutput: capture.read(capture.outputURL),
            standardError: capture.read(capture.errorURL)
        )
    }

    // MARK: - Private
}

/// Two files standing in for the child's streams, and the handles it writes them through.
private struct Capture {
    // MARK: - Property
    let outputURL: URL
    let errorURL: URL
    let output: FileHandle
    let error: FileHandle

    // MARK: - Initializer
    init() {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("open-package-capture-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        self.outputURL = root.appendingPathComponent("stdout")
        self.errorURL = root.appendingPathComponent("stderr")

        for url in [outputURL, errorURL] {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }

        self.output = (try? FileHandle(forWritingTo: outputURL)) ?? .nullDevice
        self.error = (try? FileHandle(forWritingTo: errorURL)) ?? .nullDevice
    }

    // MARK: - Public
    func read(_ url: URL) -> String {
        String(decoding: (try? Data(contentsOf: url)) ?? Data(), as: UTF8.self)
    }

    func remove() {
        try? output.close()
        try? error.close()
        try? FileManager.default.removeItem(at: outputURL.deletingLastPathComponent())
    }

    // MARK: - Private
}
