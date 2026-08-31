//
//  BuiltinCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

/// The names this runner answers itself, and what each of them reaches for.
///
/// It lives on this side because it is about the command line rather than about the
/// format: the library offers what can be done to a package, and naming those doings is
/// the surface's own business. A different surface over the same library would claim
/// different words, and the library would not have to change.
enum BuiltinCommand: String, CaseIterable, Sendable {
    case run
    case check
    case spec
    case new

    // MARK: - Property
    var summary: String {
        switch self {
        case .run:
            return "Run one of the package's own commands by name"

        case .check:
            return "Inspect the layout and the manifest"

        case .spec:
            return "Print the specification"

        case .new:
            return "Create a package"
        }
    }

    // MARK: - Public
    /// Whether this runner answers the name itself, which is the same question as whether a
    /// manifest command by that name is reachable by the short form. `help` is not a case
    /// here, since the parser owns it, but it is claimed just as firmly, so the answer lives
    /// in one place.
    static func shadows(_ name: String) -> Bool {
        name == "help" || BuiltinCommand(rawValue: name) != nil
    }
}
