//
//  Call.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

/// A call to one of the package's own commands, with the runner's words told from the
/// command's. The short form and `run` are one call written two ways, so the split is
/// computed once for both.
///
/// The line is the name. Before it the words are the runner's; after it they are the
/// command's, and the runner does not read them.
struct Call {
    // MARK: - Property
    /// `nil` for `run` with nothing after it: a call to the package with no name in it.
    /// Separate from the calls that are not the package's at all, which `init` returns `nil`
    /// for and the parser answers.
    let name: String?
    let arguments: [String]
    /// Asked for by the runner's own words, which is the only place it can be asked for.
    let json: Bool

    // MARK: - Initializer
    /// `nil` when the words are not a call to a package command, and belong to the parser.
    init?(_ words: [String]) {
        var rest = words[...]
        var asked = false

        Self.take(&rest, asking: &asked)

        // `run <name>` is the long way of writing `<name>`, so it is read here too. Left to
        // the parser, the name's own options would be read as the runner's.
        let long = rest.first == BuiltinCommand.run.rawValue

        if long {
            rest = rest.dropFirst()

            Self.take(&rest, asking: &asked)
        }

        // `--` says the next word is a name rather than an option, which is the only way a
        // command whose name begins with `-` is read as a name at all.
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

    /// Whether these words reach the package rather than the runner.
    ///
    /// The two words say different things. `run` says the name is the package's whatever the
    /// runner would otherwise make of that word, and the terminator says only that the next
    /// word is a name rather than an option. So a name the runner answers itself stays the
    /// runner's in the short form however it is spelled, and `open-package --` with nothing
    /// after it names nobody and is left to the parser to answer with the listing.
    private static func reaches(_ name: String?, after long: Bool, terminated: Bool) -> Bool {
        guard !long else { return terminated || !option(name) }
        guard let name else { return false }

        switch CommandName(name).conflict {
        case .none: return true
        case .option: return terminated
        case .reserved: return false
        }
    }

    /// Whether the parser would read this word rather than take it as a name. Absent counts
    /// as not one: `run` with nothing after it is a call that names nothing, which is this
    /// surface's to answer rather than the parser's.
    private static func option(_ word: String?) -> Bool {
        word?.hasPrefix("-") ?? false
    }

    /// Moves the runner's own words off the front, by vocabulary rather than by shape.
    /// Reading `-x` as the runner's because of its shape would take a command named `-x` on
    /// its way to being run, and `run -- -x` is the specification's way to reach it.
    private static func take(_ rest: inout ArraySlice<String>, asking asked: inout Bool) {
        while let first = rest.first, first == OutputFormat.flag {
            asked = true
            rest = rest.dropFirst()
        }
    }
}
