import Foundation

/// Protocol defining the repository interface for military abbreviations
protocol AbbreviationRepositoryProtocol {
    /// Returns all abbreviations
    var allAbbreviations: [PayslipAbbreviation] { get }
    
    /// Returns the abbreviation for the given code, if it exists
    func abbreviation(forCode code: String) -> PayslipAbbreviation?
    
    /// Returns all abbreviations in the given category
    func abbreviations(inCategory category: AbbreviationCategory) -> [PayslipAbbreviation]
    
    /// Returns all credit abbreviations
    var creditAbbreviations: [PayslipAbbreviation] { get }
    
    /// Returns all debit abbreviations
    var debitAbbreviations: [PayslipAbbreviation] { get }
}

/// Manages in-memory storage and access to military abbreviations
final class AbbreviationRepository: AbbreviationRepositoryProtocol {
    // MARK: - Properties
    
    /// The main array storing all loaded abbreviations.
    private var abbreviations: [PayslipAbbreviation] = []
    /// A dictionary mapping abbreviation codes to `PayslipAbbreviation` objects for quick lookups.
    private var abbreviationDict: [String: PayslipAbbreviation] = [:]
    
    // MARK: - Initialization
    
    /// Initializes the repository with a list of abbreviations.
    /// Builds the internal dictionary for efficient code lookups upon initialization.
    /// - Parameter abbreviations: The list of `PayslipAbbreviation` objects to manage.
    init(abbreviations: [PayslipAbbreviation]) {
        self.abbreviations = abbreviations
        buildDictionary()
    }
    
    // MARK: - AbbreviationRepositoryProtocol
    
    var allAbbreviations: [PayslipAbbreviation] {
        abbreviations
    }
    
    func abbreviation(forCode code: String) -> PayslipAbbreviation? {
        abbreviationDict[code]
    }
    
    func abbreviations(inCategory category: AbbreviationCategory) -> [PayslipAbbreviation] {
        abbreviations.filter { $0.category == category }
    }
    
    var creditAbbreviations: [PayslipAbbreviation] {
        abbreviations.filter { $0.isCredit == true }
    }
    
    var debitAbbreviations: [PayslipAbbreviation] {
        abbreviations.filter { $0.isCredit == false }
    }
    
    // MARK: - Private Methods
    
    /// Builds or rebuilds the internal dictionary mapping codes to abbreviations.
    /// This is used for efficient lookups by code.
    private func buildDictionary() {
        abbreviationDict = [:]
        for abbreviation in abbreviations {
            abbreviationDict[abbreviation.code] = abbreviation
        }
    }
} 