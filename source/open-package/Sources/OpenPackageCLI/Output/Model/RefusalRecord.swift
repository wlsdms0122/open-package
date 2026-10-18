//
//  RefusalRecord.swift
//  OpenPackageCLI
//
//  Created by JSilver on 9/11/26.
//

/// Separate keys, so a caller matching on `reason` does not break when `next` is reworded.
struct RefusalRecord: Encodable {
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
