//
//  InspectionRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Reads the package around a place and judges it against the specification. Finding the
/// package is part of the work rather than something asked of the caller, since a runner is
/// invoked from wherever a person happens to stand.
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
        let manifest = try directory.manifest()

        return Inspection(
            manifest: manifest,
            diagnosis: PackageInspector(directory: directory, manifest: manifest).inspect()
        )
    }

    // MARK: - Private
}
