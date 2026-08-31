//
//  SpecCommand.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import ArgumentParser
import Foundation
import OpenPackage

struct SpecCommand: ParsableCommand {
    // MARK: - Property
    static let configuration = CommandConfiguration(
        commandName: BuiltinCommand.spec.rawValue,
        abstract: "Print the specification.",
        discussion: """
            Answers without a package around it. This is what someone who does not know the specification asks first, and they may be standing anywhere.

            The text printed here is a summary that travels inside every package. The normative text is document/SPEC.md in the open-package repository, and where the two disagree, that document wins.

            EXAMPLES
                open-package spec
            """
    )

    // MARK: - Initializer
    // MARK: - Public
    func run() throws {
        Output.write(SpecificationRunner().run())
    }

    // MARK: - Private
}
