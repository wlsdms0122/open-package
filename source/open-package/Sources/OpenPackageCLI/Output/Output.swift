//
//  Output.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// The two streams a command line writes on. A caller that pipes this binary reads one and
/// the person watching reads the other, so which one a line goes to decides who sees it.
enum Output {
    static func write(_ text: String) {
        print(text)
    }

    static func writeError(_ text: String) {
        FileHandle.standardError.write(Data("\(text)\n".utf8))
    }
}
