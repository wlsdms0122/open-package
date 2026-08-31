//
//  TOMLError.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

public struct TOMLError: Error, Equatable, CustomStringConvertible, Sendable {
    // MARK: - Property
    public let line: Int
    public let reason: String

    public var description: String {
        "line \(line): \(reason)"
    }

    // MARK: - Initializer
    init(line: Int, reason: String) {
        self.line = line
        self.reason = reason
    }

    // MARK: - Public
    // MARK: - Private
}
