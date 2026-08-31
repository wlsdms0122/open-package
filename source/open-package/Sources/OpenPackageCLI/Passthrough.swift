//
//  Passthrough.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import OpenPackage

/// Sends anything that is not a built-in to the package's own commands, so that
/// `open-package build` reads the way `npm run build` does rather than needing a verb in
/// front of it.
struct Passthrough {
    // MARK: - Property
    private let origin: URL

    // MARK: - Initializer
    init(origin: URL) {
        self.origin = origin
    }

    // MARK: - Public
    /// The exit code to leave with, or `nil` when the arguments belong to the parser.
    ///
    /// A name this surface has not already spent goes to the package, and goes there before
    /// the parser sees it. Reaching the parser first would mean `open-package build -o out`
    /// dying on an option that was never addressed to it.
    func status(for arguments: [String]) -> Int32? {
        guard let name = arguments.first, CommandName(name).isRunnable else { return nil }

        do {
            return try CommandRunner(origin: origin)
                .run(name, arguments: Array(arguments.dropFirst()))
        } catch {
            Output.writeError("\(Refusal(error))")

            return 1
        }
    }

    // MARK: - Private
}
