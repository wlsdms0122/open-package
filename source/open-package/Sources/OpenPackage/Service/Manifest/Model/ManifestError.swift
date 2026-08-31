//
//  ManifestError.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Why the file that should say what this package is cannot be taken as it stands. They
/// are ordered by how far reading got: no file, no text, no TOML, no stated open-package,
/// and one this runner cannot speak for. They are kept apart because each sends the reader
/// somewhere else to fix it.
///
/// The last is not the manifest being wrong; it is this binary being the wrong one to read
/// it. It sits here because the gate is passed on the way to a manifest, and a requirement
/// that is absent, unreadable or too new is one question asked three times.
public enum ManifestError: Error, CustomStringConvertible, Sendable {
    case unreadable(URL, reason: String)
    case malformed(TOMLError)
    case undeclaredRequirement
    case unreadableRequirement(String)
    case unspeakableRequirement(required: Version)

    // MARK: - Property
    public var description: String {
        switch self {
        // Missing, unreadable and not-UTF-8 are three different things to go and fix, and the
        // TOML error beside this one keeps its cause down to the line. Carry it.
        case let .unreadable(url, reason):
            return "cannot read \(url.path): \(reason)"

        case let .malformed(error):
            return "\(PackageLayout.manifest) \(error.description)"

        case .undeclaredRequirement:
            return """
                \(PackageLayout.manifest) has no [open-package] version. \
                A package must state which open-package it is written for.
                """

        case let .unreadableRequirement(text):
            return "[open-package] version is not a version: \(text)"

        case let .unspeakableRequirement(required):
            return """
                this package is written for open-package \(required), and this is \(Environment.version).
                \(required > Environment.version ? "Update the runner." : "Use the runner the package was written for.")
                """
        }
    }
}
