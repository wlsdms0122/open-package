//
//  CallError.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

enum CallError: Error, CustomStringConvertible {
    case unnamed
    /// A dispatch bug, not a caller error.
    case undispatched(String)

    // MARK: - Property
    var description: String {
        switch self {
        case .unnamed:
            return "'\(BuiltinCommand.run.rawValue)' needs the name of one of the package's commands"

        case let .undispatched(name):
            return "'\(name)' was not dispatched before the parser, which it always is"
        }
    }
}
