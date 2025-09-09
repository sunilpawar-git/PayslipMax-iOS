import Foundation

/// Represents an extraction event for analytics
struct ExtractionEvent: Codable, Sendable {
    /// Type of event
    let type: ExtractionEventType

    /// When the event occurred
    let timestamp: Date

    /// Time taken for extraction (if applicable)
    let extractionTime: TimeInterval?

    /// Type of error (if applicable)
    let errorType: String?

    /// User feedback (if applicable)
    let userFeedback: UserFeedback?
}

/// Represents user feedback on extraction
struct UserFeedback: Codable, Sendable {
    /// Whether the extraction was accurate
    let isAccurate: Bool

    /// User-provided correction (if any)
    let correction: String?
}

/// Represents a pattern test event
struct PatternTestEvent: Codable, Sendable {
    /// ID of the pattern
    let patternID: UUID

    /// Key for the pattern
    let key: String

    /// Whether the test was successful
    let isSuccess: Bool

    /// When the test occurred
    let timestamp: Date
}
