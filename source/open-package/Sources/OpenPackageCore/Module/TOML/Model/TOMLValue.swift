//
//  TOMLValue.swift
//  OpenPackageCore
//
//  Created by JSilver on 8/30/26.
//

package enum TOMLValue: Equatable, Sendable {
    case string(String)
    case integer(Int)
    case boolean(Bool)
    case array([TOMLValue])
}
