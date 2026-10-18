//
//  InspectionRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

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

        // Whitespace runs nothing and exits 0, a success without having run.
        for command in manifest.commands
        where command.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnosis.fail("[command] \(command.name) is empty")
        }

        // A missing executable is a fact about this machine, not a defect, so it only warns.
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
