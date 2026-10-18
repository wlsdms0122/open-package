//
//  ManifestDeclaration.swift
//  OpenPackage
//
//  Created by JSilver on 10/18/26.
//

enum ManifestDeclaration: Sendable {
    case absent
    /// No `[open-package]` table.
    case foreign
    /// Has an `[open-package]` table, however the rest reads.
    case declared
    /// Not UTF-8. Treated as a package so that loading it reports the error.
    case unreadable
}
