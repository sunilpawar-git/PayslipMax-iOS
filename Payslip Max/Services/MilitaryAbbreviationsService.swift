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

// MARK: - Abbreviation Database

/// Manages the database of payslip abbreviations
class MilitaryAbbreviationsDatabase {
    /// Shared instance of the abbreviation database
    static let shared = MilitaryAbbreviationsDatabase()
    
    /// Array of all abbreviations
    var abbreviations: [PayslipAbbreviation] = []
    
    /// Dictionary for faster lookups by code
    private var abbreviationDict: [String: PayslipAbbreviation] = [:]
    
    /// Private initializer to enforce singleton pattern
    private init() {
        loadAbbreviations()
    }
    
    /// Loads abbreviations from the bundled JSON file or falls back to hardcoded values
    private func loadAbbreviations() {
        // Hardcoded abbreviations
        abbreviations = createHardcodedAbbreviations()
        
        // Build dictionary for faster lookups
        for abbreviation in abbreviations {
            abbreviationDict[abbreviation.code] = abbreviation
        }
        
        print("Loaded \(abbreviations.count) military abbreviations")
    }
    
    /// Creates a hardcoded list of abbreviations
    private func createHardcodedAbbreviations() -> [PayslipAbbreviation] {
        return [
            // Basic Pay
            PayslipAbbreviation(code: "BPAY", description: "Basic Pay", category: .basic, isCredit: true),
            PayslipAbbreviation(code: "GPAY", description: "Grade Pay", category: .basic, isCredit: true),
            PayslipAbbreviation(code: "MSP", description: "Military Service Pay", category: .basic, isCredit: true),
            PayslipAbbreviation(code: "PERSPAY", description: "PERSONAL PAY", category: .basic, isCredit: true),
            
            // Allowances
            PayslipAbbreviation(code: "DA", description: "Dearness Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "ADA1", description: "Additional Dearness Allowance - 1", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "ADA2", description: "Additional Dearness Allowance - 2", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "HRA1", description: "House Rent Allowance 1", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "HRA2", description: "House Rent Allowance 2", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "HRA3", description: "House Rent Allowance 3", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "HRAX", description: "House Rent Allowance X class city", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "HRAY", description: "House Rent Allowance Y class city", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "HRAZ", description: "House Rent Allowance Z class city", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "DSOP", description: "Defense Services Officers Provident Fund", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "DSOPINT", description: "DSOP INTEREST", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "DSOPREF", description: "DSOP Refund", category: .allowance, isCredit: true),
            
            // Transport Allowances
            PayslipAbbreviation(code: "TRAN1", description: "Transport Allowance Y class", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "TRAN2", description: "Transport Allowance X class", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "TRAN3", description: "Transport Allowance Y class for Blind/Disabled", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "TRAN4", description: "Transport Allowance X class for Blind/Disabled", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "TRAN5", description: "Transport Allowance for Lt General", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "TPTA", description: "Transport Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "TPTADA", description: "Transport Allowance DA", category: .allowance, isCredit: true),
            
            // Deductions
            PayslipAbbreviation(code: "INCTAX", description: "Income Tax", category: .tax, isCredit: false),
            PayslipAbbreviation(code: "ITAX", description: "Income Tax", category: .tax, isCredit: false),
            PayslipAbbreviation(code: "SURCH", description: "Surcharge on IT", category: .tax, isCredit: false),
            PayslipAbbreviation(code: "EDCESS", description: "Education Cess on IT", category: .tax, isCredit: false),
            PayslipAbbreviation(code: "EHCESS", description: "Education & Health Cess", category: .tax, isCredit: false),
            
            // Awards and Medals
            PayslipAbbreviation(code: "AC", description: "Ashok Chakra", category: .award, isCredit: true),
            PayslipAbbreviation(code: "KC", description: "Kirti Chakra", category: .award, isCredit: true),
            PayslipAbbreviation(code: "SC", description: "Shaurya Chakra", category: .award, isCredit: true),
            PayslipAbbreviation(code: "VC", description: "Vir Chakra", category: .award, isCredit: true),
            PayslipAbbreviation(code: "MVC", description: "Maha Vir Chakra", category: .award, isCredit: true),
            PayslipAbbreviation(code: "PVC", description: "Param Vir Chakra", category: .award, isCredit: true),
            
            // Compensatory Allowances
            PayslipAbbreviation(code: "BCA", description: "Bhutan Compensatory Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "BCAS1", description: "Bhutan Compensatory Allowance with one servant", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "BCAS2", description: "Bhutan Compensatory Allowance with two servant", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "MCA", description: "Myanmar Compensatory Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "MCAS1", description: "Myanmar Compensatory Allowance with one servant", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "MCAS2", description: "Myanmar Compensatory Allowance with two servant", category: .allowance, isCredit: true),
            
            // Special Allowances
            PayslipAbbreviation(code: "SICHA", description: "Siachen Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "HAFA", description: "Highly Active Field Area Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "CFAA", description: "Compensatory Field Area Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "CMFA", description: "Compensatory Modified Area Allowance", category: .allowance, isCredit: true),
            
            // Additional Allowances
            PayslipAbbreviation(code: "ADBANKC", description: "Adjustment against Bank CR", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "ADBNKDR", description: "Adjustment against Bank DR", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADCGEIS", description: "Adjustment CGEIS", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "ADCGHIS", description: "Adjustment CGHIS", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "ADCGHS", description: "Adjustment CGHS", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "ADCSD", description: "Adjustment CSD", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADDSOP", description: "Adjustment DSOP", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADGPF", description: "Adjustment GPF", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADHBA", description: "Adjustment HBA", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADHBAI", description: "Adjustment HBA Interest", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADIT", description: "Adjustment Income Tax", category: .tax, isCredit: false),
            PayslipAbbreviation(code: "ADLIC", description: "Adjustment LIC", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "ADLOAN", description: "Adjustment Loan", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADLOANI", description: "Adjustment Loan Interest", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADLTA", description: "Adjustment LTA", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "ADMC", description: "Adjustment MC", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADNGIS", description: "Adjustment NGIS", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "ADPLI", description: "Adjustment PLI", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "ADRENT", description: "Adjustment Rent", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ADWATER", description: "Adjustment Water", category: .deduction, isCredit: false),
            
            // Arrears
            PayslipAbbreviation(code: "ARR-DA", description: "Arrears - Dearness Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "ARR-SPCDO", description: "Arrears - Special Compensatory Duty Allowance", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "ARR-TPTADA", description: "Arrears - Transport Allowance DA", category: .allowance, isCredit: true),
            
            // Insurance and Funds
            PayslipAbbreviation(code: "AGIF", description: "Army Group Insurance Fund", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "CGEIS", description: "Central Government Employees Insurance Scheme", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "CGHIS", description: "Central Government Health Insurance Scheme", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "CGHS", description: "Central Government Health Scheme", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "GPF", description: "General Provident Fund", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "NGIS", description: "Naval Group Insurance Scheme", category: .insurance, isCredit: false),
            
            // Loans and Advances
            PayslipAbbreviation(code: "HBA", description: "House Building Advance", category: .advance, isCredit: true),
            PayslipAbbreviation(code: "HBAI", description: "House Building Advance Interest", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "LOAN", description: "Loan", category: .advance, isCredit: true),
            PayslipAbbreviation(code: "LOANI", description: "Loan Interest", category: .deduction, isCredit: false),
            
            // Miscellaneous
            PayslipAbbreviation(code: "CSD", description: "Canteen Stores Department", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "ETKT", description: "E-Ticket", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "FUR", description: "Furniture", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "LF", description: "License Fee", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "LTC", description: "Leave Travel Concession", category: .allowance, isCredit: true),
            PayslipAbbreviation(code: "MC", description: "Mess Charges", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "PLI", description: "Postal Life Insurance", category: .insurance, isCredit: false),
            PayslipAbbreviation(code: "RENT", description: "Rent", category: .deduction, isCredit: false),
            PayslipAbbreviation(code: "WATER", description: "Water Charges", category: .deduction, isCredit: false)
        ]
    }
    
    /// Finds an abbreviation by its code
    /// - Parameter code: The abbreviation code to look up
    /// - Returns: The matching abbreviation, if found
    func findAbbreviation(code: String) -> PayslipAbbreviation? {
        return abbreviationDict[code]
    }
    
    /// Finds abbreviations by partial match in code or description
    /// - Parameter text: The text to search for
    /// - Returns: An array of matching abbreviations
    func findByPartialMatch(text: String) -> [PayslipAbbreviation] {
        return abbreviations.filter {
            text.contains($0.code) ||
            text.lowercased().contains($0.description.lowercased())
        }
    }
    
    /// Finds the closest matching abbreviation using fuzzy matching
    /// - Parameter text: The text to match
    /// - Returns: The closest matching abbreviation, if any
    func findClosestAbbreviation(text: String) -> PayslipAbbreviation? {
        // Exact match first
        if let exact = findAbbreviation(code: text) {
            return exact
        }
        
        // Try fuzzy matching
        var bestMatch: (abbreviation: PayslipAbbreviation, score: Int) = (abbreviations[0], Int.max)
        
        for abbr in abbreviations {
            let distance = levenshteinDistance(text, abbr.code)
            if distance < bestMatch.score && distance <= 2 { // Max 2 character difference
                bestMatch = (abbr, distance)
            }
        }
        
        return bestMatch.score <= 2 ? bestMatch.abbreviation : nil
    }
    
    /// Calculates the Levenshtein distance between two strings
    /// - Parameters:
    ///   - a: First string
    ///   - b: Second string
    /// - Returns: The Levenshtein distance
    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a)
        let b = Array(b)
        
        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        
        for i in 0...a.count {
            dist[i][0] = i
        }
        
        for j in 0...b.count {
            dist[0][j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    dist[i][j] = dist[i-1][j-1]
                } else {
                    dist[i][j] = min(
                        dist[i-1][j] + 1,      // deletion
                        dist[i][j-1] + 1,      // insertion
                        dist[i-1][j-1] + 1     // substitution
                    )
                }
            }
        }
        
        return dist[a.count][b.count]
    }
    
    /// Gets all abbreviations in a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: An array of abbreviations in the specified category
    func getAbbreviations(inCategory category: AbbreviationCategory) -> [PayslipAbbreviation] {
        return abbreviations.filter { $0.category == category }
    }
    
    /// Gets all credit abbreviations
    /// - Returns: An array of credit abbreviations
    func getCreditAbbreviations() -> [PayslipAbbreviation] {
        return abbreviations.filter { $0.isCredit == true }
    }
    
    /// Gets all debit abbreviations
    /// - Returns: An array of debit abbreviations
    func getDebitAbbreviations() -> [PayslipAbbreviation] {
        return abbreviations.filter { $0.isCredit == false }
    }
}

// MARK: - Regex Manager

/// Manages regex patterns for payslip parsing
class MilitaryRegexManager {
    /// Shared instance of the regex manager
    static let shared = MilitaryRegexManager()
    
    /// The abbreviation database
    private let abbreviationDB = MilitaryAbbreviationsDatabase.shared
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Generates a regex pattern that matches all known pay codes
    var payCodePattern: String {
        let codes = abbreviationDB.abbreviations.map { $0.code }
        return "\\b(\(codes.joined(separator: "|")))\\b"
    }
    
    /// Basic patterns for different payslip formats
    var basicPatterns: [PayslipRegexPattern] {
        [
            // Basic pattern for code-amount pairs
            PayslipRegexPattern(
                pattern: "\\b([A-Z0-9]+)\\b[\\s\\:]+(\\d+\\.?\\d*)",
                group: 1,
                type: .payCode,
                description: "Generic code-amount pair"
            ),
            
            // Pattern for section headers
            PayslipRegexPattern(
                pattern: "\\b(ALLOWANCES|DEDUCTIONS|CREDITS|DEBITS|EARNINGS|PAYMENTS|RECOVERIES)\\b",
                group: 1,
                type: .section,
                description: "Section header"
            ),
            
            // Pattern for name
            PayslipRegexPattern(
                pattern: "(?:Name|Employee)[\\s\\:]+([A-Za-z\\s]+)",
                group: 1,
                type: .name,
                description: "Employee name"
            ),
            
            // Pattern for account number
            PayslipRegexPattern(
                pattern: "(?:A/C|Account)[\\s\\:]+([A-Z0-9]+)",
                group: 1,
                type: .accountNumber,
                description: "Account number"
            ),
            
            // Pattern for PAN
            PayslipRegexPattern(
                pattern: "(?:PAN|PAN No)[\\s\\:]+([A-Z0-9]+)",
                group: 1,
                type: .panNumber,
                description: "PAN number"
            ),
            
            // Pattern for location
            PayslipRegexPattern(
                pattern: "(?:Location|Station|Place)[\\s\\:]+([A-Za-z\\s]+)",
                group: 1,
                type: .location,
                description: "Location"
            )
        ]
    }
    
    /// Generates dynamic patterns based on known abbreviations
    func generateDynamicPatterns() -> [PayslipRegexPattern] {
        let allCodes = abbreviationDB.abbreviations.map { $0.code }
        let codesPattern = allCodes.joined(separator: "|")
        
        return [
            // Pattern for tabular format
            PayslipRegexPattern(
                pattern: "\\b(\(codesPattern))\\b\\s+(\\d+\\.?\\d*)",
                group: 1,
                type: .payCode,
                description: "Tabular format code-amount pair"
            ),
            
            // Pattern for colon-separated format
            PayslipRegexPattern(
                pattern: "\\b(\(codesPattern))\\b\\s*:\\s*(\\d+\\.?\\d*)",
                group: 1,
                type: .payCode,
                description: "Colon-separated code-amount pair"
            ),
            
            // Pattern for labeled format
            PayslipRegexPattern(
                pattern: "(\(codesPattern))\\s+[A-Za-z\\s]+\\s+(\\d+\\.?\\d*)",
                group: 1,
                type: .payCode,
                description: "Labeled code-amount pair"
            )
        ]
    }
    
    /// Gets all patterns (basic and dynamic)
    var allPatterns: [PayslipRegexPattern] {
        return basicPatterns + generateDynamicPatterns()
    }
    
    /// Compiles a regex pattern
    /// - Parameter pattern: The pattern string
    /// - Returns: A compiled NSRegularExpression
    func compile(pattern: String) -> NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            print("Error compiling regex pattern: \(error)")
            return nil
        }
    }
}

// MARK: - Parser Service

/// Service for parsing payslips using the abbreviation database and regex patterns
class MilitaryPayslipParserService {
    /// Shared instance of the parser service
    static let shared = MilitaryPayslipParserService()
    
    /// The abbreviation database
    private let abbreviationDB = MilitaryAbbreviationsDatabase.shared
    
    /// The regex manager
    private let regexManager = MilitaryRegexManager.shared
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Parses a payslip from text
    /// - Parameter text: The text to parse
    /// - Returns: An array of PayslipLineItem
    func parsePayslip(from text: String) -> [PayslipLineItem] {
        return parseLineItems(from: text)
    }
    
    /// Parses line items from text
    /// - Parameter text: The text to parse
    /// - Returns: An array of PayslipLineItem
    func parseLineItems(from text: String) -> [PayslipLineItem] {
        var lineItems: [PayslipLineItem] = []
        var currentSection: String?
        
        // Get all patterns
        let patterns = regexManager.allPatterns
        
        // Process each line
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            // Check if this line is a section header
            if let sectionPattern = patterns.first(where: { $0.type == .section }),
               let regex = regexManager.compile(pattern: sectionPattern.pattern) {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                let matches = regex.matches(in: line, options: [], range: range)
                
                if let match = matches.first, match.numberOfRanges > sectionPattern.group,
                   let matchRange = Range(match.range(at: sectionPattern.group), in: line) {
                    currentSection = String(line[matchRange]).uppercased()
                }
            }
            
            // Look for pay code patterns
            for pattern in patterns.filter({ $0.type == .payCode }) {
                guard let regex = regexManager.compile(pattern: pattern.pattern) else {
                    continue
                }
                
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                let matches = regex.matches(in: line, options: [], range: range)
                
                for match in matches {
                    if match.numberOfRanges > pattern.group + 1,
                       let codeRange = Range(match.range(at: pattern.group), in: line),
                       let amountRange = Range(match.range(at: pattern.group + 1), in: line) {
                        
                        let code = String(line[codeRange])
                        let amountString = String(line[amountRange])
                        
                        if let amount = Double(amountString) {
                            // Try to find the abbreviation
                            if let abbreviation = abbreviationDB.findAbbreviation(code: code) {
                                // Use the abbreviation data
                                let isCredit = abbreviation.isCredit ?? determineIfCredit(code: code, section: currentSection)
                                
                                let lineItem = PayslipLineItem(
                                    code: code,
                                    description: abbreviation.description,
                                    amount: amount,
                                    isCredit: isCredit,
                                    category: abbreviation.category
                                )
                                
                                lineItems.append(lineItem)
                            } else {
                                // Try fuzzy matching
                                if let closestMatch = abbreviationDB.findClosestAbbreviation(text: code) {
                                    let isCredit = closestMatch.isCredit ?? determineIfCredit(code: code, section: currentSection)
                                    
                                    let lineItem = PayslipLineItem(
                                        code: code,
                                        description: closestMatch.description,
                                        amount: amount,
                                        isCredit: isCredit,
                                        category: closestMatch.category
                                    )
                                    
                                    lineItems.append(lineItem)
                                } else {
                                    // Unknown code, make a best guess
                                    let isCredit = determineIfCredit(code: code, section: currentSection)
                                    
                                    let lineItem = PayslipLineItem(
                                        code: code,
                                        description: code,
                                        amount: amount,
                                        isCredit: isCredit,
                                        category: .other
                                    )
                                    
                                    lineItems.append(lineItem)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return lineItems
    }
    
    /// Determines if a code represents a credit based on context
    /// - Parameters:
    ///   - code: The code to check
    ///   - section: The current section (if known)
    /// - Returns: Whether the code likely represents a credit
    private func determineIfCredit(code: String, section: String?) -> Bool {
        // Use section information if available
        if let section = section {
            if section.contains("ALLOWANCE") || section.contains("CREDIT") || section.contains("EARNING") || section.contains("PAYMENT") {
                return true
            }
            if section.contains("DEDUCTION") || section.contains("DEBIT") || section.contains("RECOVERY") {
                return false
            }
        }
        
        // Make a best guess based on common patterns
        if code.contains("TAX") || code.contains("SURCH") || code.contains("CESS") {
            return false
        }
        
        // Default to credit
        return true
    }
}

// MARK: - Integration with Existing Services

/// Extension to integrate with the existing DefaultPDFExtractor
extension DefaultPDFExtractor {
    /// Extracts text from a PDF document
    /// - Parameter document: The PDF document
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument) -> String {
        var extractedText = ""
        
        // Extract text from each page
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let pageText = page.string ?? ""
            extractedText += pageText
        }
        
        return extractedText
    }
    
    /// Enhances extraction with military abbreviation support
    /// - Parameter document: The PDF document to extract from
    /// - Returns: Enhanced payslip data
    func extractWithMilitaryAbbreviations(from document: PDFDocument) async throws -> PayslipItem {
        // First use the standard extraction
        let basicPayslip = try await extractPayslipData(from: document) as! PayslipItem
        
        // Extract text from the document
        let text = extractText(from: document)
        
        // Parse line items using the military parser
        let lineItems = MilitaryPayslipParserService.shared.parseLineItems(from: text)
        
        // Calculate totals
        let creditItems = lineItems.filter { $0.isCredit }
        let debitItems = lineItems.filter { !$0.isCredit }
        
        let totalCredits = creditItems.reduce(0) { $0 + $1.amount }
        let totalDebits = debitItems.reduce(0) { $0 + $1.amount }
        
        // Only update if we found values and the original is zero or very small
        if totalCredits > 0 && (basicPayslip.credits == 0 || basicPayslip.credits < totalCredits * 0.5) {
            basicPayslip.credits = totalCredits
        }
        
        if totalDebits > 0 && (basicPayslip.debits == 0 || basicPayslip.debits < totalDebits * 0.5) {
            basicPayslip.debits = totalDebits
        }
        
        // Look for DSOP specifically
        if let dsopItem = lineItems.first(where: { $0.code == "DSOP" }) {
            basicPayslip.dsop = dsopItem.amount
        }
        
        // Look for tax specifically
        if let taxItem = lineItems.first(where: { $0.code == "INCTAX" }) {
            basicPayslip.tax = taxItem.amount
        }
        
        return basicPayslip
    }
}

/// Extension to integrate with the DIContainer
extension DIContainer {
    /// Creates a military-enhanced PDF extractor
    /// - Returns: A PDF extractor with military abbreviation support
    func createMilitaryEnhancedPDFExtractor() -> PDFExtractorProtocol {
        // Initialize the military abbreviations database
        _ = MilitaryAbbreviationsDatabase.shared
        
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
 let payslip = try await extractor.extractWithMilitaryAbbreviations(from: pdfDocument)
 ```
 
 3. To access the abbreviation database directly:
 
 ```
 let database = MilitaryAbbreviationsDatabase.shared
 let abbreviation = database.findAbbreviation(code: "DSOP")
 ```
 */ 