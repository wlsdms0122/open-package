//
//  Inspection.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// `diagnosis` is mutable so a caller can add findings the specification cannot know.
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
