//
//  Runtime.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import Foundation

struct Runtime {
    // MARK: - Property
    let origin: URL

    // MARK: - Initializer
    init() {
        self.origin = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    // MARK: - Public
    func resolve(_ path: String) -> URL {
        URL(fileURLWithPath: path, relativeTo: origin).standardizedFileURL
    }

    // MARK: - Private
}
