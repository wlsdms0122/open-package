//
//  PackageLayout.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// What a package has to hold on disk, which is its manifest and nothing more. Everything
/// else in the directory is arranged however the package likes.
public enum PackageLayout {
    public static let manifest = "manifest.toml"
}
