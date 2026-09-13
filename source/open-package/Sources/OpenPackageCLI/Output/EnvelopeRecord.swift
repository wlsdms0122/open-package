//
//  EnvelopeRecord.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

/// What may go inside an envelope: something that encodes as a JSON object, and leaves
/// `runner` to the envelope.
///
/// The object part is not optional. A record that encodes as an array or a single value
/// makes the envelope open a keyed container on an encoder already holding another kind,
/// and `JSONEncoder` ends the process there rather than raising.
protocol EnvelopeRecord: Encodable { }
