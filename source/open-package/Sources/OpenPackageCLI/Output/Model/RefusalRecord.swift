//
//  RefusalRecord.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

/// Why the runner printed nothing else. The cause and the way out are two keys rather than
/// one paragraph, so a caller matching on what went wrong does not break when the advice
/// beside it is reworded.
struct RefusalRecord: EnvelopeRecord {
    // MARK: - Property
    let reason: String
    let next: String?

    // MARK: - Initializer
    init(_ refusal: Refusal) {
        self.reason = refusal.cause
        self.next = refusal.next
    }

    init(reason: String) {
        self.reason = reason
        self.next = nil
    }

    // MARK: - Public
    // MARK: - Private
}
