//
//  PackageVersionToolError.swift
//  PackageVersionTool
//
//  Created by JSilver on 10/18/26.
//

enum PackageVersionToolError: Error, CustomStringConvertible {
    case undeclaredVersion
    case unreadableVersion(String)

    var description: String {
        switch self {
        case .undeclaredVersion:
            "[package] version is missing"

        case let .unreadableVersion(version):
            "[package] version '\(version)' is not major.minor.patch"
        }
    }
}
