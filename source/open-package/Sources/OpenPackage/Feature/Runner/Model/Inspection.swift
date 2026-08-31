//
//  Inspection.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// What an inspection found, and what it was looking at. The manifest travels with the
/// diagnosis because whoever asked has to name the package it is about, and because a
/// caller that knows something the specification cannot, such as which names its own
/// surface has taken, adds what it knows to the same report.
public struct Inspection: Sendable {
    // MARK: - Property
    public let manifest: Manifest
    public var diagnosis: Diagnosis

    // MARK: - Initializer
    init(manifest: Manifest, diagnosis: Diagnosis) {
        self.manifest = manifest
        self.diagnosis = diagnosis
    }

    // MARK: - Public
    // MARK: - Private
}
