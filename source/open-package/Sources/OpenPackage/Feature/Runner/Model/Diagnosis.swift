//
//  Diagnosis.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// Errors make a package invalid; warnings do not.
public struct Diagnosis: Sendable {
    // MARK: - Property
    public private(set) var errors: [String] = []
    public private(set) var warnings: [String] = []

    public var isValid: Bool { errors.isEmpty }
    public var isClean: Bool { errors.isEmpty && warnings.isEmpty }

    public var report: String {
        (errors.map { "error  \($0)" } + warnings.map { "warn   \($0)" })
            .joined(separator: "\n")
    }

    // MARK: - Initializer
    init() { }

    // MARK: - Public
    mutating func fail(_ message: String) {
        errors.append(message)
    }

    public mutating func warn(_ message: String) {
        warnings.append(message)
    }

    // MARK: - Private
}
