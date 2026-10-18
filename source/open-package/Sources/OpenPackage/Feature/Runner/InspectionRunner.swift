//
//  InspectionRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Judges the manifest of the package around a place against the specification. Whether the
/// package does its job is what its own commands answer.
public struct InspectionRunner: Sendable {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    public init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    public func run() throws -> Inspection {
        let manifest = try PackageLocator(origin: origin).package().manifest()
        var diagnosis = Diagnosis()

        if manifest.name.isEmpty { diagnosis.fail("[package] name is missing") }
        if manifest.version.isEmpty { diagnosis.fail("[package] version is missing") }

        // A body of whitespace runs nothing and exits 0, which is success without having run.
        for command in manifest.commands
        where command.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnosis.fail("[command] \(command.name) is empty")
        }

        // Whether this machine can run the package is a fact about the machine, not a defect.
        for requirement in manifest.requires where !isExecutableOnPath(requirement) {
            diagnosis.warn("required executable is not on PATH here: \(requirement)")
        }

        return Inspection(manifest: manifest, diagnosis: diagnosis)
    }

    // MARK: - Private
    private func isExecutableOnPath(_ name: String) -> Bool {
        (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .contains { FileManager.default.isExecutableFile(atPath: "\($0)/\(name)") }
    }
}
