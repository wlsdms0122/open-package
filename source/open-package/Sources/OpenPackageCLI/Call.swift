//
//  Call.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

/// A short-form or `run` call. Words before the name are the runner's; words after it are
/// the command's.
struct Call {
    // MARK: - Property
    /// `nil` for `run` with nothing after it.
    let name: String?
    let arguments: [String]
    let json: Bool

    // MARK: - Initializer
    /// `nil` when the words belong to the parser.
    init?(_ words: [String]) {
        var rest = words[...]
        var asked = false

        Self.take(&rest, asking: &asked)

        // Read here, not by the parser, so the command's options are not read as the runner's.
        let long = rest.first == BuiltinCommand.run.rawValue

        if long {
            rest = rest.dropFirst()

            Self.take(&rest, asking: &asked)
        }

        // `--` is the only way to reach a name starting with `-`.
        let terminated = rest.first == Self.terminator

        if terminated { rest = rest.dropFirst() }

        let name = rest.first

        guard Self.reaches(name, after: long, terminated: terminated) else { return nil }

        self.name = name
        self.arguments = Array(rest.dropFirst())
        self.json = asked
    }

    // MARK: - Public
    // MARK: - Private
    private static let terminator = "--"

    /// After `run`, any name is the package's; `--` only lets a name start with `-`, so a
    /// reserved name stays the runner's in the short form.
    private static func reaches(_ name: String?, after long: Bool, terminated: Bool) -> Bool {
        guard !long else { return terminated || !option(name) }
        guard let name else { return false }

        switch CommandName(name).conflict {
        case .none: return true
        case .option: return terminated
        case .reserved: return false
        }
    }

    /// Absent is not an option, so a bare `run` is answered here rather than by the parser.
    private static func option(_ word: String?) -> Bool {
        word?.hasPrefix("-") ?? false
    }

    /// Matches by vocabulary, not shape, so a command named `-x` is not consumed.
    private static func take(_ rest: inout ArraySlice<String>, asking asked: inout Bool) {
        while let first = rest.first, first == OutputFormat.flag {
            asked = true
            rest = rest.dropFirst()
        }
    }
}
