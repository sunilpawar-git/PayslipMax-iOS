import Foundation

/// Protocol for military abbreviation services providing access, matching, and normalization capabilities.
/// This protocol enables dependency injection and testability for military payslip processing.
protocol MilitaryAbbreviationServiceProtocol {
    
    // MARK: - Data Access
    
    /// Returns all loaded abbreviations.
    var allAbbreviations: [PayslipAbbreviation] { get }
    
    /// Returns all abbreviations classified as credits.
    var creditAbbreviations: [PayslipAbbreviation] { get }
    
    /// Returns all abbreviations classified as debits.
    var debitAbbreviations: [PayslipAbbreviation] { get }
    
    // MARK: - Lookup Methods
    
    /// Returns the abbreviation for the given code, if it exists.
    /// - Parameter code: The abbreviation code (e.g., "BPAY").
    /// - Returns: The matching `PayslipAbbreviation` or `nil` if not found.
    func abbreviation(forCode code: String) -> PayslipAbbreviation?
    
    /// Returns all abbreviations in the specified category.
    /// - Parameter category: The `AbbreviationCategory` to filter by.
    /// - Returns: An array of `PayslipAbbreviation` objects in that category.
    func abbreviations(inCategory category: AbbreviationCategory) -> [PayslipAbbreviation]
    
    /// Matches a text string (potentially a code or description) to an abbreviation.
    /// Tries matching as a code first, then as a description.
    /// - Parameter text: The text string to match.
    /// - Returns: The matching `PayslipAbbreviation` or `nil` if no match is found.
    func match(text: String) -> PayslipAbbreviation?
    
    // MARK: - Normalization
    
    /// Normalizes a pay component name using predefined mappings and capitalization rules.
    /// Attempts to map common variations (case-insensitive, partial matches) to a standard name.
    /// If no mapping is found, it applies title-case capitalization.
    /// - Parameter componentName: The raw component name extracted from the payslip.
    /// - Returns: A standardized, user-friendly component name.
    func normalizePayComponent(_ componentName: String) -> String
}

// MARK: - Default Implementation

/// Default implementation of MilitaryAbbreviationServiceProtocol that delegates to the existing singleton.
/// This maintains backward compatibility while enabling dependency injection.
final class MilitaryAbbreviationService: MilitaryAbbreviationServiceProtocol {
    
    // MARK: - Properties
    
    /// The loader responsible for reading abbreviation data from the source (e.g., JSON).
    private let loader: AbbreviationLoader
    /// The repository holding the loaded abbreviation data in memory.
    private let repository: AbbreviationRepository
    /// The matcher used for finding abbreviations based on code or description.
    private let matcher: AbbreviationMatcher
    /// Mappings from common variations to standardized component names.
    private var componentMappings: [String: String]
    
    // MARK: - Initialization
    
    /// Initializes with dependency injection capability.
    /// Loads abbreviations and mappings using the `AbbreviationLoader`.
    /// Falls back to empty data if loading fails, logging an error.
    init(loader: AbbreviationLoader? = nil) {
        self.loader = loader ?? AbbreviationLoader()
        
        do {
            let abbreviations = try self.loader.loadAbbreviations()
            self.componentMappings = try self.loader.loadComponentMappings()
            self.repository = AbbreviationRepository(abbreviations: abbreviations)
        } catch {
            print("Failed to load abbreviations from JSON: \(error)")
            // Instead of using hardcoded abbreviations, initialize with an empty collection
            // This encourages fixing the JSON load issue rather than relying on outdated hardcoded values
            self.componentMappings = [:]
            self.repository = AbbreviationRepository(abbreviations: [])
        }
        
        self.matcher = AbbreviationMatcher(repository: repository)
    }
    
    // MARK: - Data Access
    
    var allAbbreviations: [PayslipAbbreviation] {
        repository.allAbbreviations
    }
    
    var creditAbbreviations: [PayslipAbbreviation] {
        repository.creditAbbreviations
    }
    
    var debitAbbreviations: [PayslipAbbreviation] {
        repository.debitAbbreviations
    }
    
    // MARK: - Lookup Methods
    
    func abbreviation(forCode code: String) -> PayslipAbbreviation? {
        matcher.match(code: code)
    }
    
    func abbreviations(inCategory category: AbbreviationCategory) -> [PayslipAbbreviation] {
        repository.abbreviations(inCategory: category)
    }
    
    func match(text: String) -> PayslipAbbreviation? {
        matcher.match(text: text)
    }
    
    // MARK: - Normalization
    
    func normalizePayComponent(_ componentName: String) -> String {
        let normalizedName = componentName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for exact matches first
        if let exactMatch = componentMappings[normalizedName.lowercased()] {
            return exactMatch
        }
        
        // Check for partial matches
        for (key, value) in componentMappings {
            if normalizedName.lowercased().contains(key) {
                return value
            }
        }
        
        // If no match found, capitalize the first letter of each word
        return normalizedName.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

// MARK: - Bridge Implementation for Backward Compatibility

/// Bridge implementation that delegates to the existing singleton for backward compatibility.
/// This allows gradual migration from singleton to dependency injection.
final class MilitaryAbbreviationServiceBridge: MilitaryAbbreviationServiceProtocol {
    
    // MARK: - Data Access
    
    var allAbbreviations: [PayslipAbbreviation] {
        MilitaryAbbreviationsService.shared.allAbbreviations
    }
    
    var creditAbbreviations: [PayslipAbbreviation] {
        MilitaryAbbreviationsService.shared.creditAbbreviations
    }
    
    var debitAbbreviations: [PayslipAbbreviation] {
        MilitaryAbbreviationsService.shared.debitAbbreviations
    }
    
    // MARK: - Lookup Methods
    
    func abbreviation(forCode code: String) -> PayslipAbbreviation? {
        MilitaryAbbreviationsService.shared.abbreviation(forCode: code)
    }
    
    func abbreviations(inCategory category: AbbreviationCategory) -> [PayslipAbbreviation] {
        MilitaryAbbreviationsService.shared.abbreviations(inCategory: category)
    }
    
    func match(text: String) -> PayslipAbbreviation? {
        MilitaryAbbreviationsService.shared.match(text: text)
    }
    
    // MARK: - Normalization
    
    func normalizePayComponent(_ componentName: String) -> String {
        MilitaryAbbreviationsService.shared.normalizePayComponent(componentName)
    }
}
