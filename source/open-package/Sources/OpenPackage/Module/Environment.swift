//
//  Environment.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// The binary that is running. What that version is allowed to mean is the format's
/// question, and is answered beside the manifest field that asks it.
public enum Environment {
    public static let version = Version(major: 1, minor: 1, patch: 0)
}
