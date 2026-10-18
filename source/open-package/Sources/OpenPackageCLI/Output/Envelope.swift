//
//  Envelope.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import OpenPackage

/// A JSON line: the record's keys, and beside them `runner`, the binary that wrote it. The
/// record must encode as an object, since `JSONEncoder` traps on a keyed container opened
/// over an array or a single value.
struct Envelope<Record: Encodable>: Encodable {
    // MARK: - Property
    private let record: Record

    private enum CodingKeys: String, CodingKey {
        case runner
    }

    // MARK: - Initializer
    init(_ record: Record) {
        self.record = record
    }

    // MARK: - Public
    func encode(to encoder: Encoder) throws {
        try record.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(Environment.version)", forKey: .runner)
    }

    // MARK: - Private
}
