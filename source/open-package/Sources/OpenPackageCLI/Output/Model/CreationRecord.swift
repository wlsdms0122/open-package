//
//  CreationRecord.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

/// Where a package was just created, and the name it was created under. The path is
/// absolute, since the caller is not necessarily standing where it will look next.
struct CreationRecord: EnvelopeRecord {
    // MARK: - Property
    let created: String
    let name: String

    // MARK: - Initializer
    // MARK: - Public
    // MARK: - Private
}
