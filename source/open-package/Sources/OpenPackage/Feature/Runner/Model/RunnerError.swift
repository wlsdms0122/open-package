//
//  RunnerError.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// Why this runner will not do what it was asked, although nothing it was given is wrong.
/// A name that is not in the manifest is a sound manifest met by the wrong word.
public enum RunnerError: Error, CustomStringConvertible, Sendable {
    case unknownCommand(String)

    // MARK: - Property
    public var description: String {
        switch self {
        case let .unknownCommand(name):
            return "no such command: \(name)"
        }
    }
}
