//
//  Inspection.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// What an inspection found, and what it was looking at. The manifest travels with the
/// diagnosis so that whoever asked can name the package it is about, and so that a caller
/// knowing something the specification cannot, such as which names its own surface has
/// taken, adds it to the same report.
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
