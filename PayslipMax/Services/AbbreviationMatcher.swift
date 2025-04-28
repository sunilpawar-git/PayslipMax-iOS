import Foundation

/// Protocol defining the matcher interface for military abbreviations
protocol AbbreviationMatcherProtocol {
    /// Matches a code to an abbreviation
    /// - Parameter code: The code to match
    /// - Returns: The matching abbreviation, if found
    func match(code: String) -> PayslipAbbreviation?
    
    /// Matches a description to an abbreviation
    /// - Parameter description: The description to match
    /// - Returns: The matching abbreviation, if found
    func match(description: String) -> PayslipAbbreviation?
    
    /// Matches a code or description to an abbreviation
    /// - Parameter text: The text to match (could be code or description)
    /// - Returns: The matching abbreviation, if found
    func match(text: String) -> PayslipAbbreviation?
}

/// Handles matching logic for military abbreviations
final class AbbreviationMatcher: AbbreviationMatcherProtocol {
    // MARK: - Properties
    
    /// The repository providing access to the abbreviation data.
    private let repository: AbbreviationRepositoryProtocol
    
    // MARK: - Initialization
    
    /// Initializes the matcher with an abbreviation repository.
    /// - Parameter repository: The repository used to fetch abbreviation data for matching.
    init(repository: AbbreviationRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - AbbreviationMatcherProtocol
    
    func match(code: String) -> PayslipAbbreviation? {
        repository.abbreviation(forCode: code)
    }
    
    func match(description: String) -> PayslipAbbreviation? {
        repository.allAbbreviations.first { $0.description.lowercased() == description.lowercased() }
    }
    
    func match(text: String) -> PayslipAbbreviation? {
        // Try matching as code first (faster)
        if let abbreviation = match(code: text) {
            return abbreviation
        }
        
        // Then try matching as description
        return match(description: text)
    }
} 