//
//  PackageVersion.swift
//  PackageVersion
//
//  Created by JSilver on 10/18/26.
//

import Foundation
import PackagePlugin

@main
struct PackageVersion: BuildToolPlugin {
    // MARK: - Property
    // MARK: - Initializer
    // MARK: - Lifecycle
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // The runner is built from `source/open-package` of the open-package it is the runner of.
        let manifest = context.package.directoryURL.appending(path: "../../manifest.toml").standardized
        let output = context.pluginWorkDirectoryURL.appending(path: "PackageVersion.swift")

        return [
            .buildCommand(
                displayName: "Reading the runner's version from \(manifest.path)",
                executable: try context.tool(named: "PackageVersionTool").url,
                arguments: [manifest.path, output.path],
                inputFiles: [manifest],
                outputFiles: [output]
            )
        ]
    }

    // MARK: - Public
    // MARK: - Private
}
