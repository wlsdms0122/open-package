//
//  Output.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import Foundation

/// The two streams a command line answers on. What belongs on which is not a detail: a
/// caller that pipes this binary reads one of them and the person watching reads the
/// other, so an answer printed to the wrong stream is an answer nobody asked for.
enum Output {
    static func write(_ text: String) {
        print(text)
    }

    static func writeError(_ text: String) {
        FileHandle.standardError.write(Data("\(text)\n".utf8))
    }
}
