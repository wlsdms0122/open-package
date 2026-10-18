//
//  Output.swift
//  OpenPackageCLI
//
//  Created by JSilver on 8/30/26.
//

import Foundation

enum Output {
    static func write(_ text: String) {
        print(text)
    }

    static func writeError(_ text: String) {
        FileHandle.standardError.write(Data("\(text)\n".utf8))
    }
}
