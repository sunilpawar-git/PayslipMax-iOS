import Foundation

/// An extraction issue.
struct ExtractionIssue {
    /// The field with the issue.
    let field: String
    
    /// The number of occurrences of the issue.
    let occurrences: Int
    
    /// A description of the issue.
    let description: String
} 