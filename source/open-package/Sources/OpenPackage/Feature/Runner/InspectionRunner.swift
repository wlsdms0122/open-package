//
//  InspectionRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Reads the package around a place and judges it against the specification.
///
/// Finding it is part of the work rather than something asked of the caller. A runner is
/// invoked from wherever a person happens to stand, and the walk upward is what turns that
/// into one answer.
public struct InspectionRunner: Sendable {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    public init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    public func run() throws -> Inspection {
        let directory = try PackageLocator(origin: origin).package()
        let manifest = try directory.speakableManifest()

        return Inspection(
            manifest: manifest,
            diagnosis: PackageInspector(directory: directory, manifest: manifest).inspect()
        )
    }

    // MARK: - Private
}
