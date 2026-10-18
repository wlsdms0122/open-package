//
//  RunnerError.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

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
