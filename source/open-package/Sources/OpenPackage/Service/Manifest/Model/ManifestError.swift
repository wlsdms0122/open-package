//
//  ManifestError.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import OpenPackageCore

public enum ManifestError: Error, CustomStringConvertible, Sendable {
    case unreadable(URL, reason: String)
    case malformed(TOMLError)
    case undeclaredRunnerVersion
    case unreadableRunnerVersion(String)
    case unsupportedRunnerVersion(required: Version)

    // MARK: - Property
    public var description: String {
        switch self {
        case let .unreadable(url, reason):
            return "cannot read \(url.path): \(reason)"

        case let .malformed(error):
            return "\(Manifest.fileName) \(error.description)"

        case .undeclaredRunnerVersion:
            return """
                \(Manifest.fileName) has no [\(Manifest.declaration)] version. \
                A package must state which open-package it is written for.
                """

        case let .unreadableRunnerVersion(text):
            return "[\(Manifest.declaration)] version is not a version: \(text)"

        case let .unsupportedRunnerVersion(required):
            return """
                this package is written for open-package \(required), and this is \(Environment.version).
                \(required > Environment.version ? "Update the runner." : "Use the runner the package was written for.")
                """
        }
    }
}
