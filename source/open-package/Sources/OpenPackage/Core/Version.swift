//
//  Version.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

public struct Version: Equatable, Comparable, CustomStringConvertible, Sendable {
    // MARK: - Property
    public let major: Int
    public let minor: Int
    public let patch: Int

    public var description: String { "\(major).\(minor).\(patch)" }

    // MARK: - Initializer
    init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init?(_ text: String) {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false).map(String.init)

        guard (1...3).contains(parts.count) else { return nil }

        // Digits only. `Int("+1")` succeeds, and a version has one written form. A second
        // spelling of the same number puts two names on one compatibility axis.
        guard parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else { return nil }

        let numbers = parts.compactMap(Int.init)
        guard numbers.count == parts.count, numbers.allSatisfy({ $0 >= 0 }) else { return nil }

        self.init(
            major: numbers[0],
            minor: numbers.count > 1 ? numbers[1] : 0,
            patch: numbers.count > 2 ? numbers[2] : 0
        )
    }

    // MARK: - Public
    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }

    // MARK: - Private
}
