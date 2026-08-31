//
//  PackageLayout.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// The only entries a package may keep at its top level. Everything else belongs inside
/// `source/` or `document/`, so that the role of a package is readable at a glance.
public enum PackageLayout {
    public static let manifest = "manifest.toml"
    public static let readme = "README.md"
    public static let source = "source"
    public static let document = "document"

    static func allows(_ entry: String) -> Bool {
        if entry.hasPrefix(".") { return true }
        if entry.hasPrefix("LICENSE") { return true }

        return [source, document, manifest, readme].contains(entry)
    }
}
