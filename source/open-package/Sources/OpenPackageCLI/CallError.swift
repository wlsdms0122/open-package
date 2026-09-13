//
//  CallError.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

/// What is wrong with a call to one of the package's commands, as this surface sees it. A
/// call with no name in it is still the package's, so it is answered here and in the form
/// that was asked for rather than handed to the parser.
enum CallError: Error, CustomStringConvertible {
    case unnamed
    /// A call that should have been dispatched before the parser and was not, which is a
    /// defect in what this surface dispatches rather than anything the caller wrote.
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
