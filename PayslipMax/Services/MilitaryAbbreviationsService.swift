//
//  MilitaryAbbreviationsService.swift
//  Payslip Max
//
//  Created by Claude on 11/03/25.
//

import Foundation
import PDFKit

// MARK: - Models

/// Represents a payslip abbreviation with its description and category
struct PayslipAbbreviation: Codable, Identifiable, Hashable {
    /// The unique identifier for the abbreviation (same as code)
    var id: String { code }
    
    /// The abbreviation code (e.g., "BPAY", "DA")
    let code: String
    
    /// The full description of the abbreviation (e.g., "Basic Pay", "Dearness Allowance")
    let description: String
    
    /// The category the abbreviation belongs to (e.g., `.allowance`, `.deduction`)
    let category: AbbreviationCategory
    
    /// Indicates if the abbreviation typically represents a credit (`true`), debit (`false`), or can be either (`nil`)
    let isCredit: Bool?
}

/// Categories for payslip abbreviations
enum AbbreviationCategory: String, Codable, CaseIterable {
    /// Core pay components.
    case basic = "Basic Pay"
    /// Additional payments or benefits.
    case allowance = "Allowances"
    /// Amounts subtracted from pay.
    case deduction = "Deductions"
    /// Reimbursement for expenses.
    case reimbursement = "Reimbursements"
    /// Payments related to awards or medals.
    case award = "Awards and Medals"
    /// Payments made in advance.
    case advance = "Advances"
    /// Recurring payments for services or memberships.
    case subscription = "Subscriptions"
    /// Fees or charges applied.
    case charge = "Charges"
    /// Tax-related deductions.
    case tax = "Taxes"
    /// Insurance-related deductions.
    case insurance = "Insurance"
    /// Category for items that don't fit elsewhere.
    case other = "Other"
}

/// Represents an item in a payslip (credit or debit)
struct PayslipLineItem: Identifiable, Hashable {
    /// Unique identifier for the line item.
    let id = UUID()
    
    /// The code associated with this item (e.g., "BPAY", "DA")
    let code: String
    
    /// The description of this item as it appears on the payslip.
    let description: String
    
    /// The monetary amount of this item.
    let amount: Double
    
    /// Indicates if this item is a credit (`true`) or a debit (`false`)
    let isCredit: Bool
    
    /// The determined category of this item based on its code or description.
    let category: AbbreviationCategory
}

/// Represents a regex pattern for extracting payslip data
struct PayslipRegexPattern {
    /// The regular expression pattern string.
    let pattern: String
    
    /// The index of the capture group containing the desired data within the pattern.
    let group: Int
    
    /// The type of data this pattern is designed to extract.
    let type: PatternType
    
    /// A human-readable description of what this pattern matches.
    let description: String
}

/// Types of data that can be extracted using `PayslipRegexPattern`.
enum PatternType {
    /// A standard pay code or abbreviation.
    case payCode
    /// A monetary amount.
    case amount
    /// A date.
    case date
    /// A person's name.
    case name
    /// A bank account number.
    case accountNumber
    /// A PAN (Permanent Account Number).
    case panNumber
    /// A geographical location or unit.
    case location
    /// A section header or title.
    case section
}

// MARK: - Service Implementation

/// Service for managing military abbreviations, providing access, matching, and normalization capabilities.
/// Uses a loader, repository, and matcher internally. Implemented as a Singleton.
final class MilitaryAbbreviationsService {
    // MARK: - Properties
    
    /// Shared singleton instance of the service.
    static let shared = MilitaryAbbreviationsService()
    
    /// The loader responsible for reading abbreviation data from the source (e.g., JSON).
    private let loader: AbbreviationLoader
    /// The repository holding the loaded abbreviation data in memory.
    private let repository: AbbreviationRepository
    /// The matcher used for finding abbreviations based on code or description.
    private let matcher: AbbreviationMatcher
    /// Mappings from common variations to standardized component names.
    private var componentMappings: [String: String]
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern.
    /// Loads abbreviations and mappings using the `AbbreviationLoader`.
    /// Initializes the repository and matcher.
    /// Falls back to empty data if loading fails, logging an error.
    private init() {
        self.loader = AbbreviationLoader()
        
        do {
            let abbreviations = try loader.loadAbbreviations()
            self.componentMappings = try loader.loadComponentMappings()
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
    
    // MARK: - Public Methods
    
    /// Returns all loaded abbreviations.
    var allAbbreviations: [PayslipAbbreviation] {
        repository.allAbbreviations
    }
    
    /// Returns the abbreviation for the given code, if it exists.
    /// - Parameter code: The abbreviation code (e.g., "BPAY").
    /// - Returns: The matching `PayslipAbbreviation` or `nil` if not found.
    func abbreviation(forCode code: String) -> PayslipAbbreviation? {
        matcher.match(code: code)
    }
    
    /// Returns all abbreviations in the specified category.
    /// - Parameter category: The `AbbreviationCategory` to filter by.
    /// - Returns: An array of `PayslipAbbreviation` objects in that category.
    func abbreviations(inCategory category: AbbreviationCategory) -> [PayslipAbbreviation] {
        repository.abbreviations(inCategory: category)
    }
    
    /// Returns all abbreviations classified as credits.
    var creditAbbreviations: [PayslipAbbreviation] {
        repository.creditAbbreviations
    }
    
    /// Returns all abbreviations classified as debits.
    var debitAbbreviations: [PayslipAbbreviation] {
        repository.debitAbbreviations
    }
    
    /// Matches a text string (potentially a code or description) to an abbreviation.
    /// Tries matching as a code first, then as a description.
    /// - Parameter text: The text string to match.
    /// - Returns: The matching `PayslipAbbreviation` or `nil` if no match is found.
    func match(text: String) -> PayslipAbbreviation? {
        matcher.match(text: text)
    }
    
    /// Normalizes a pay component name using predefined mappings and capitalization rules.
    /// Attempts to map common variations (case-insensitive, partial matches) to a standard name.
    /// If no mapping is found, it applies title-case capitalization.
    /// - Parameter componentName: The raw component name extracted from the payslip.
    /// - Returns: A standardized, user-friendly component name.
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

// MARK: - Integration with Existing Services

/// Extension to integrate `MilitaryAbbreviationsService` functionality with `DefaultPDFExtractor`.
extension DefaultPDFExtractor {
    /// Extracts text from a PDF document. Currently, this implementation does not specifically
    /// expand or handle military abbreviations during extraction itself.
    /// Abbreviation handling is typically done *after* text extraction.
    /// - Parameter document: The PDF document.
    /// - Returns: The extracted text from all pages concatenated.
    func extractMilitaryText(from document: PDFDocument) -> String {
        var extractedText = ""
        
        // Extract text from each page
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let pageText = page.string ?? ""
            extractedText += pageText
        }
        
        return extractedText
    }
}

/// Extension to integrate `MilitaryAbbreviationsService` with the `DIContainer`.
extension DIContainer {
    /// Creates a `DefaultPDFExtractor` instance.
    /// Ensures the `MilitaryAbbreviationsService` singleton is initialized before returning the extractor.
    /// - Returns: A `PDFExtractorProtocol` instance (currently `DefaultPDFExtractor`).
    func createMilitaryEnhancedPDFExtractor() -> PDFExtractorProtocol {
        // Initialize the military abbreviations service
        _ = MilitaryAbbreviationsService.shared
        
        // Return the default extractor (which now has the military extension)
        return DefaultPDFExtractor()
    }
}

// MARK: - Usage Example

/*
 To use the military abbreviations service in your app:
 
 1. Update DIContainer.swift to use the military-enhanced PDF extractor:
 
 ```
 func createPDFExtractor() -> PDFExtractorProtocol {
     return createMilitaryEnhancedPDFExtractor()
 }
 ```
 
 2. Or use it directly in your code:
 
 ```
 let extractor = DefaultPDFExtractor()
 if let payslip = await extractor.extractWithMilitaryAbbreviations(from: pdfDocument) {
     // Use payslip
 }
 ```
 
 3. To access the abbreviation service directly:
 
 ```
 let service = MilitaryAbbreviationsService.shared
 let abbreviation = service.abbreviation(forCode: "DSOP")
 ```
 */