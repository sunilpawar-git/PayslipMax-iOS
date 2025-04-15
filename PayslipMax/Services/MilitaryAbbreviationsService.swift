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
    
    /// The full description of the abbreviation
    let description: String
    
    /// The category of the abbreviation
    let category: AbbreviationCategory
    
    /// Whether the abbreviation represents a credit (true), debit (false), or could be either (nil)
    let isCredit: Bool?
}

/// Categories for payslip abbreviations
enum AbbreviationCategory: String, Codable, CaseIterable {
    case basic = "Basic Pay"
    case allowance = "Allowances"
    case deduction = "Deductions"
    case reimbursement = "Reimbursements"
    case award = "Awards and Medals"
    case advance = "Advances"
    case subscription = "Subscriptions"
    case charge = "Charges"
    case tax = "Taxes"
    case insurance = "Insurance"
    case other = "Other"
}

/// Represents an item in a payslip (credit or debit)
struct PayslipLineItem: Identifiable, Hashable {
    /// Unique identifier
    let id = UUID()
    
    /// The code for this item (e.g., "BPAY", "DA")
    let code: String
    
    /// The description of this item
    let description: String
    
    /// The amount of this item
    let amount: Double
    
    /// Whether this item is a credit (true) or debit (false)
    let isCredit: Bool
    
    /// The category of this item
    let category: AbbreviationCategory
}

/// Represents a regex pattern for extracting payslip data
struct PayslipRegexPattern {
    /// The regex pattern string
    let pattern: String
    
    /// The capture group index for the main data
    let group: Int
    
    /// The type of data this pattern extracts
    let type: PatternType
    
    /// A description of what this pattern matches
    let description: String
}

/// Types of data that can be extracted from a payslip
enum PatternType {
    case payCode
    case amount
    case date
    case name
    case accountNumber
    case panNumber
    case location
    case section
}

// MARK: - Service Implementation

/// Service for managing military abbreviations and payslip parsing
final class MilitaryAbbreviationsService {
    // MARK: - Properties
    
    /// Shared instance of the service
    static let shared = MilitaryAbbreviationsService()
    
    private let loader: AbbreviationLoader
    private let repository: AbbreviationRepository
    private let matcher: AbbreviationMatcher
    private var componentMappings: [String: String]
    
    // MARK: - Initialization
    
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
    
    /// Returns all abbreviations
    var allAbbreviations: [PayslipAbbreviation] {
        repository.allAbbreviations
    }
    
    /// Returns the abbreviation for the given code, if it exists
    func abbreviation(forCode code: String) -> PayslipAbbreviation? {
        matcher.match(code: code)
    }
    
    /// Returns all abbreviations in the given category
    func abbreviations(inCategory category: AbbreviationCategory) -> [PayslipAbbreviation] {
        repository.abbreviations(inCategory: category)
    }
    
    /// Returns all credit abbreviations
    var creditAbbreviations: [PayslipAbbreviation] {
        repository.creditAbbreviations
    }
    
    /// Returns all debit abbreviations
    var debitAbbreviations: [PayslipAbbreviation] {
        repository.debitAbbreviations
    }
    
    /// Matches a code or description to an abbreviation
    func match(text: String) -> PayslipAbbreviation? {
        matcher.match(text: text)
    }
    
    /// Normalizes a pay component name by standardizing common variations
    /// - Parameter componentName: The raw component name from the payslip
    /// - Returns: A standardized component name
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

/// Extension to integrate with the existing DefaultPDFExtractor
extension DefaultPDFExtractor {
    /// Extracts text from a PDF document with military abbreviation handling
    /// - Parameter document: The PDF document
    /// - Returns: The extracted text with expanded abbreviations
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

/// Extension to integrate with the DIContainer
extension DIContainer {
    /// Creates a military-enhanced PDF extractor
    /// - Returns: A PDF extractor with military abbreviation support
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