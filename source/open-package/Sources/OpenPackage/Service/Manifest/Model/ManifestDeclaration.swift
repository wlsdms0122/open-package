//
//  ManifestDeclaration.swift
//  OpenPackage
//
//  Created by JSilver on 10/18/26.
//

/// What a `manifest.toml` says about whose file it is, read before the file is taken as a
/// manifest.
enum ManifestDeclaration: Sendable {
    /// No file there.
    case absent
    /// A file of some other format, with no `[open-package]` table.
    case foreign
    /// A file that opens an `[open-package]` table, however the rest of it reads.
    case declared
    /// A file that cannot be read as text, so whose it is cannot be told. TOML is UTF-8, so
    /// it is not a valid file of any format, and reading it as a package says what is wrong.
    case unreadable
}
