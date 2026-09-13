//
//  SpecificationRecord.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

/// The summary this runner carries, handed over whole. It stays prose inside the field,
/// since the normative document has no structure for this surface to mirror.
struct SpecificationRecord: EnvelopeRecord {
    // MARK: - Property
    let specification: String

    // MARK: - Initializer
    // MARK: - Public
    // MARK: - Private
}
