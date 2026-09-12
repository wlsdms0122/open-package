//
//  ManifestError.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// Why the file that should say what this package is cannot be taken as it stands, ordered
/// by how far reading got: no file, no text, no TOML, no stated open-package, and one this
/// runner does not support. Each sends the reader somewhere else to fix it.
///
/// The last one is this binary being the wrong one to read the manifest rather than the
/// manifest being wrong. It sits here because the gate is passed on the way to a manifest.
public enum ManifestError: Error, CustomStringConvertible, Sendable {
    case unreadable(URL, reason: String)
    case malformed(TOMLError)
    case undeclaredRunnerVersion
    case unreadableRunnerVersion(String)
    case unsupportedRunnerVersion(required: Version)

    // MARK: - Property
    public var description: String {
        switch self {
        // Missing, unreadable and not-UTF-8 are three different things to go and fix, and the
        // TOML error beside this one keeps its cause down to the line. Carry it.
        case let .unreadable(url, reason):
            return "cannot read \(url.path): \(reason)"

        case let .malformed(error):
            return "\(PackageLayout.manifest) \(error.description)"

        case .undeclaredRunnerVersion:
            return """
                \(PackageLayout.manifest) has no [open-package] version. \
                A package must state which open-package it is written for.
                """

        case let .unreadableRunnerVersion(text):
            return "[open-package] version is not a version: \(text)"

        case let .unsupportedRunnerVersion(required):
            return """
                this package is written for open-package \(required), and this is \(Environment.version).
                \(required > Environment.version ? "Update the runner." : "Use the runner the package was written for.")
                """
        }
    }
}
