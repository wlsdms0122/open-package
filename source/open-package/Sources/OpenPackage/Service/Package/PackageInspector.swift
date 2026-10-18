//
//  PackageInspector.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Checks a package against the specification only. Whether the package does its job is
/// what its own commands answer, and this deliberately does not ask it.
struct PackageInspector: Sendable {
    // MARK: - Property
    private let manifest: Manifest

    // MARK: - Initializer
    init(manifest: Manifest) {
        self.manifest = manifest
    }

    // MARK: - Public
    func inspect() -> Diagnosis {
        var diagnosis = Diagnosis()

        inspectIdentity(&diagnosis)
        inspectRequirements(&diagnosis)
        inspectCommands(&diagnosis)

        return diagnosis
    }

    // MARK: - Private
    /// The directory name is not read here. Which package this is, is where it is (section 6),
    /// so there is nothing in the manifest for it to agree or disagree with, and what the
    /// package calls itself is free to read like a title rather than like a path.
    private func inspectIdentity(_ diagnosis: inout Diagnosis) {
        if manifest.name.isEmpty { diagnosis.fail("[package] name is missing") }
        if manifest.version.isEmpty { diagnosis.fail("[package] version is missing") }
    }

    private func inspectRequirements(_ diagnosis: inout Diagnosis) {
        // A warning, not an error. Whether a package is well formed is a property of the
        // package; whether this machine can run it is a property of the machine, and the
        // package's own commands are where that question belongs.
        for requirement in manifest.requires where !isExecutableOnPath(requirement) {
            diagnosis.warn("required executable is not on PATH here: \(requirement)")
        }
    }

    /// Command names are not read here, only bodies. Which words a package uses is its
    /// own affair: the specification fixes no name, so there is no meaning here to hold a
    /// line to, and which names a runner has already taken is a fact about that runner's
    /// surface rather than about the format. What is left is the one thing a manifest can
    /// state and be wrong about on its face.
    private func inspectCommands(_ diagnosis: inout Diagnosis) {
        // Newlines count as empty too. `\n` is an escape the scanner supports, so a body of
        // one is writable, and a command that runs nothing exits 0, which is the package
        // claiming it works here without having looked.
        for command in manifest.commands
        where command.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnosis.fail("[command] \(command.name) is empty")
        }
    }

    private func isExecutableOnPath(_ name: String) -> Bool {
        let search = ProcessInfo.processInfo.environment["PATH"] ?? ""

        return search
            .split(separator: ":")
            .contains { FileManager.default.isExecutableFile(atPath: "\($0)/\(name)") }
    }
}
