//
//  Envelope.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

import OpenPackage

/// What every JSON line carries whatever it is about: which binary wrote it. The manifest
/// cannot say that, and a caller needs it before it can judge the rest.
///
/// The record's keys go into the same object rather than nested under one, so `runner` is a
/// key beside them and not a level around them. That is why `EnvelopeRecord` requires a
/// record to encode as an object.
struct Envelope<Record: EnvelopeRecord>: Encodable {
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
