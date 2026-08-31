//
//  TOMLValue.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// A value as it was written. Narrowing to a type is `TOMLDocument`'s job and is allowed to
/// refuse. There is deliberately no accessor here that renders one type as another, because
/// a value's type is part of the manifest's contract, and anything that erases it is a
/// second door into the shapes the scanner just turned away.
enum TOMLValue: Equatable, Sendable {
    case string(String)
    case integer(Int)
    case boolean(Bool)
    case array([TOMLValue])
}
