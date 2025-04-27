import Foundation

/// Statistics about extraction accuracy.
struct ExtractionStatistics {
    /// The total number of samples.
    let totalSamples: Int
    
    /// The number of samples with feedback.
    let samplesWithFeedback: Int
    
    /// The number of correct samples.
    let correctSamples: Int
    
    /// The number of incorrect samples.
    let incorrectSamples: Int
    
    /// The accuracy rate (correct / total with feedback).
    let accuracyRate: Double
} 