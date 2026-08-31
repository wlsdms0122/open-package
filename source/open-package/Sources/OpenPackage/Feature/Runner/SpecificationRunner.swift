//
//  SpecificationRunner.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// Produces the specification summary.
///
/// It takes no package. Someone who does not know the specification asks first and may be
/// standing anywhere, so this is the one thing the runner answers with nothing around it.
public struct SpecificationRunner: Sendable {
    // MARK: - Property
    // MARK: - Initializer
    public init() { }

    // MARK: - Public
    public func run() -> String {
        Specification.summary
    }

    // MARK: - Private
}
