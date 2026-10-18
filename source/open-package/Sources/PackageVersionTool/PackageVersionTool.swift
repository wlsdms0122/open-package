//
//  PackageVersionTool.swift
//  PackageVersionTool
//
//  Created by JSilver on 10/18/26.
//

import Foundation
import OpenPackageCore

/// Writes `packageVersion` from the manifest of the open-package the runner is built in, read
/// the way the runner reads every manifest.
@main
struct PackageVersionTool {
    // MARK: - Property
    // MARK: - Initializer
    // MARK: - Public
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())

        guard arguments.count == 2 else {
            fail("usage: PackageVersionTool <manifest.toml> <PackageVersion.swift>")
        }

        let manifest = URL(filePath: arguments[0])
        let output = URL(filePath: arguments[1])

        do {
            let version = try version(of: manifest)

            try """
            import OpenPackageCore

            let packageVersion = Version(major: \(version.major), minor: \(version.minor), patch: \(version.patch))

            """.write(to: output, atomically: true, encoding: .utf8)
        } catch {
            fail("\(manifest.path): \(error)")
        }
    }

    // MARK: - Private
    /// Only the canonical spelling is taken, so the runner reports the very string its
    /// manifest holds.
    private static func version(of manifest: URL) throws -> Version {
        let document = try TOMLParser().parse(String(contentsOf: manifest, encoding: .utf8))

        guard let declared = try document.string("package.version") else {
            throw PackageVersionToolError.undeclaredVersion
        }
        guard let version = Version(declared), version.description == declared else {
            throw PackageVersionToolError.unreadableVersion(declared)
        }

        return version
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
        exit(1)
    }
}
