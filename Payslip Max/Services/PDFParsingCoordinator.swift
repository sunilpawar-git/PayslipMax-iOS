import Foundation
import PDFKit

// MARK: - Models

/// Represents the confidence level of a parsing result
enum ParsingConfidence: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    
    static func < (lhs: ParsingConfidence, rhs: ParsingConfidence) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Represents a parsing result with confidence level
struct ParsingResult {
    let payslipItem: PayslipItem
    let confidence: ParsingConfidence
    let parserName: String
    
    init(payslipItem: PayslipItem, confidence: ParsingConfidence, parserName: String) {
        self.payslipItem = payslipItem
        self.confidence = confidence
        self.parserName = parserName
    }
}

/// Represents personal details extracted from a payslip
struct PersonalDetails {
    var name: String = ""
    var accountNumber: String = ""
    var panNumber: String = ""
    var month: String = ""
    var year: String = ""
    var location: String = ""
}

/// Represents income tax details extracted from a payslip
struct IncomeTaxDetails {
    var totalTaxableIncome: Double = 0
    var standardDeduction: Double = 0
    var netTaxableIncome: Double = 0
    var totalTaxPayable: Double = 0
    var incomeTaxDeducted: Double = 0
    var educationCessDeducted: Double = 0
}

/// Represents DSOP fund details extracted from a payslip
struct DSOPFundDetails {
    var openingBalance: Double = 0
    var subscription: Double = 0
    var miscAdjustment: Double = 0
    var withdrawal: Double = 0
    var refund: Double = 0
    var closingBalance: Double = 0
}

/// Represents a contact person extracted from a payslip
struct ContactPerson {
    var designation: String
    var name: String
    var phoneNumber: String
}

/// Represents contact details extracted from a payslip
struct ContactDetails {
    var contactPersons: [ContactPerson] = []
    var emails: [String] = []
    var website: String = ""
}

/// Protocol for payslip parsers
protocol PayslipParser {
    /// Name of the parser for identification
    var name: String { get }
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A PayslipItem if parsing is successful, nil otherwise
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem?
    
    /// Evaluates the confidence level of the parsing result
    /// - Parameter payslipItem: The parsed PayslipItem
    /// - Returns: The confidence level of the parsing result
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence
}

/// Coordinator for orchestrating different parsing strategies
class PDFParsingCoordinator {
    // MARK: - Properties
    
    /// Available parsers in order of preference
    private var parsers: [PayslipParser] = []
    
    /// Abbreviation manager for handling abbreviations
    private let abbreviationManager: AbbreviationManager
    
    /// Cache for previously parsed documents
    private var cache: [String: ParsingResult] = [:]
    
    // MARK: - Initialization
    
    init(abbreviationManager: AbbreviationManager) {
        self.abbreviationManager = abbreviationManager
        setupParsers()
    }
    
    // MARK: - Setup
    
    /// Sets up the available parsers
    private func setupParsers() {
        // Add the page-aware parser
        parsers.append(PageAwarePayslipParser(abbreviationManager: abbreviationManager))
        
        // Add the PCDA parser
        parsers.append(PCDAPayslipParser(abbreviationManager: abbreviationManager))
        
        // Add more parsers as needed
    }
    
    // MARK: - Parsing Methods
    
    /// Parses a PDF document using all available parsers and returns the best result
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: The best parsing result, or nil if all parsers failed
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        // Check if we have a cached result for this document
        if let cachedResult = getCachedResult(for: pdfDocument) {
            return cachedResult.payslipItem
        }
        
        var bestResult: PayslipItem? = nil
        var bestConfidence: ParsingConfidence = .low
        var bestParserName: String = ""
        
        // Try each parser and select the best result
        for parser in parsers {
            if let result = parser.parsePayslip(pdfDocument: pdfDocument) {
                let confidence = parser.evaluateConfidence(for: result)
                
                // If this result has higher confidence, use it
                if confidenceIsHigher(confidence, than: bestConfidence) {
                    bestResult = result
                    bestConfidence = confidence
                    bestParserName = parser.name
                }
            }
        }
        
        // Cache the best result if available
        if let result = bestResult {
            print("Selected result from parser: \(bestParserName) with confidence: \(bestConfidence)")
            let parsingResult = ParsingResult(
                payslipItem: result,
                confidence: bestConfidence,
                parserName: bestParserName
            )
            cacheResult(parsingResult, for: pdfDocument)
        }
        
        return bestResult
    }
    
    /// Parses a PDF document using a specific parser
    /// - Parameters:
    ///   - pdfDocument: The PDF document to parse
    ///   - parserName: The name of the parser to use
    /// - Returns: The parsing result, or nil if the parser failed or was not found
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) -> PayslipItem? {
        guard let parser = parsers.first(where: { $0.name == parserName }) else {
            return nil
        }
        
        return parser.parsePayslip(pdfDocument: pdfDocument)
    }
    
    // MARK: - Caching Methods
    
    /// Gets a cached result for a PDF document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: The cached result, if available
    private func getCachedResult(for pdfDocument: PDFDocument) -> ParsingResult? {
        let key = generateCacheKey(for: pdfDocument)
        return cache[key]
    }
    
    /// Caches a parsing result for a PDF document
    /// - Parameters:
    ///   - result: The parsing result to cache
    ///   - pdfDocument: The PDF document
    private func cacheResult(_ result: ParsingResult, for pdfDocument: PDFDocument) {
        let key = generateCacheKey(for: pdfDocument)
        cache[key] = result
    }
    
    /// Generates a cache key for a PDF document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: A unique cache key
    private func generateCacheKey(for pdfDocument: PDFDocument) -> String {
        // Use the document's first page text as a key
        if let firstPage = pdfDocument.page(at: 0), let text = firstPage.string {
            return text.prefix(100).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return UUID().uuidString // Fallback to a random key
    }
    
    // MARK: - Utility Methods
    
    /// Clears the parsing cache
    func clearCache() {
        cache.removeAll()
    }
    
    /// Gets the names of all available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return parsers.map { $0.name }
    }
    
    private func confidenceIsHigher(_ confidence: ParsingConfidence, than otherConfidence: ParsingConfidence) -> Bool {
        switch (confidence, otherConfidence) {
        case (.high, .medium), (.high, .low), (.medium, .low):
            return true
        default:
            return false
        }
    }
}

// MARK: - Parser Extensions

// Extension to make PageAwarePayslipParser conform to PayslipParser protocol
extension PageAwarePayslipParser: PayslipParser {
    var name: String {
        return "PageAwareParser"
    }
    
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        // Evaluate confidence based on completeness of data
        var score = 0
        
        // Check personal details
        if !payslipItem.name.isEmpty && !payslipItem.accountNumber.isEmpty {
            score += 1
        }
        
        // Check earnings and deductions
        if payslipItem.credits > 0 && payslipItem.debits > 0 {
            score += 1
        }
        
        // Check if standard fields are present
        if payslipItem.earnings["BPAY"] != nil && 
           payslipItem.deductions["DSOP"] != nil {
            score += 1
        }
        
        // Determine confidence level based on score
        if score >= 3 {
            return .high
        } else if score >= 2 {
            return .medium
        } else {
            return .low
        }
    }
}

// Extension to make EnhancedEarningsDeductionsParser conform to PayslipParser protocol
extension EnhancedEarningsDeductionsParser: PayslipParser {
    var name: String {
        return "EnhancedEarningsDeductionsParser"
    }
    
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        // Extract text from all pages
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            fullText += page.string ?? ""
        }
        
        // Create a basic PayslipItem with earnings and deductions data
        let earningsDeductionsData = extractEarningsDeductions(from: fullText)
        
        let payslipItem = PayslipItem(
            id: UUID(),
            month: getCurrentMonth(),
            year: getCurrentYear(),
            credits: earningsDeductionsData.grossPay,
            debits: earningsDeductionsData.totalDeductions,
            dsop: earningsDeductionsData.dsop,
            tax: earningsDeductionsData.itax,
            location: extractLocation(from: fullText) ?? "Unknown",
            name: extractName(from: fullText) ?? "Unknown",
            accountNumber: extractAccountNumber(from: fullText) ?? "Unknown",
            panNumber: extractPANNumber(from: fullText) ?? "Unknown"
        )
        
        // Add standard earnings
        payslipItem.earnings["BPAY"] = earningsDeductionsData.bpay
        payslipItem.earnings["DA"] = earningsDeductionsData.da
        payslipItem.earnings["MSP"] = earningsDeductionsData.msp
        
        // Add known non-standard earnings
        for (key, value) in earningsDeductionsData.knownEarnings {
            payslipItem.earnings[key] = value
        }
        
        // Add misc credits if any
        if earningsDeductionsData.miscCredits > 0 {
            payslipItem.earnings["Misc Credits"] = earningsDeductionsData.miscCredits
        }
        
        // Add standard deductions
        payslipItem.deductions["DSOP"] = earningsDeductionsData.dsop
        payslipItem.deductions["AGIF"] = earningsDeductionsData.agif
        payslipItem.deductions["ITAX"] = earningsDeductionsData.itax
        
        // Add known non-standard deductions
        for (key, value) in earningsDeductionsData.knownDeductions {
            payslipItem.deductions[key] = value
        }
        
        // Add misc debits if any
        if earningsDeductionsData.miscDebits > 0 {
            payslipItem.deductions["Misc Debits"] = earningsDeductionsData.miscDebits
        }
        
        return payslipItem
    }
    
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        // Evaluate confidence based on completeness of data
        var score = 0
        
        // Check if we have earnings and deductions
        if payslipItem.credits > 0 && payslipItem.debits > 0 {
            score += 1
        }
        
        // Check if standard fields are present
        if payslipItem.earnings["BPAY"] != nil && 
           payslipItem.deductions["DSOP"] != nil {
            score += 1
        }
        
        // Check if we have a reasonable number of items
        if payslipItem.earnings.count >= 3 && payslipItem.deductions.count >= 3 {
            score += 1
        }
        
        // Determine confidence level based on score
        if score >= 3 {
            return .high
        } else if score >= 2 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    private func getCurrentYear() -> Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: Date())
    }
    
    // Helper methods to extract additional information
    private func extractLocation(from text: String) -> String? {
        // Implement location extraction logic here
        // This is a placeholder implementation
        return "Default Location"
    }
    
    private func extractName(from text: String) -> String? {
        // Implement name extraction logic here
        // This is a placeholder implementation
        return "Default Name"
    }
    
    private func extractAccountNumber(from text: String) -> String? {
        // Implement account number extraction logic here
        // This is a placeholder implementation
        return "XXXXXXXXXX"
    }
    
    private func extractPANNumber(from text: String) -> String? {
        // Implement PAN number extraction logic here
        // This is a placeholder implementation
        return "XXXXXXXXXX"
    }
} 