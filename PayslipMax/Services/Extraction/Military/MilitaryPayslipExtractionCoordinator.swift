import Foundation
import PDFKit

/// Simplified coordinator for military payslip extraction using standard PDF processing with military patterns
///
/// This simplified service uses standard PDF extraction services with military-specific patterns,
/// eliminating the over-engineered specialized military services while maintaining functionality.
class MilitaryPayslipExtractionCoordinator {
    
    // MARK: - Dependencies
    
    /// Pattern matching service for military-specific extraction patterns
    private let patternMatchingService: PatternMatchingServiceProtocol
    
    /// Military abbreviations service for terminology handling
    private let abbreviationsService = MilitaryAbbreviationsService.shared
    
    // MARK: - Initialization
    
    /// Initializes with standard pattern matching service
    init(patternMatchingService: PatternMatchingServiceProtocol? = nil) {
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
    }
    
    // MARK: - Public Methods
    
    /// Determines if the provided text content likely originates from a military payslip.
    func isMilitaryPayslip(_ text: String) -> Bool {
        // Simple pattern check for military payslip indicators
        let militaryIndicators = ["PCDA", "DSOP", "AGIF", "BPAY", "Military Service", "Armed Forces"]
        return militaryIndicators.contains { text.localizedCaseInsensitiveContains($0) }
    }
    
    /// Extracts military payslip data using standard PDF extraction with military patterns.
    func extractMilitaryPayslipData(from text: String, pdfData: Data?) throws -> PayslipItem? {
        print("MilitaryPayslipExtractionCoordinator: Attempting simplified military payslip extraction")
        
        // Validate input
        guard text.count >= 100 else {
            print("MilitaryPayslipExtractionCoordinator: Text too short (\(text.count) chars)")
            return nil
        }
        
        // Use pattern matching service for tabular data extraction
        let (extractedEarnings, extractedDeductions) = patternMatchingService.extractTabularData(from: text)
        
        // Extract basic information using simple patterns
        let name = extractName(from: text)
        let month = extractMonth(from: text)
        let year = extractYear(from: text)
        let accountNumber = extractAccountNumber(from: text)
        
        // Process financial data with military abbreviations
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Process extracted earnings
        for (key, value) in extractedEarnings {
            let normalizedKey = abbreviationsService.normalizePayComponent(key)
            earnings[normalizedKey] = value
        }
        
        // Process extracted deductions
        for (key, value) in extractedDeductions {
            let normalizedKey = abbreviationsService.normalizePayComponent(key)
            deductions[normalizedKey] = value
        }
        
        // Calculate totals
        let credits = earnings.values.reduce(0, +)
        let debits = deductions.values.reduce(0, +)
        let tax = deductions["ITAX"] ?? deductions["IT"] ?? 0.0
        let dsop = deductions["DSOP"] ?? 0.0
        
        // Create simplified payslip
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: "",
            pdfData: pdfData ?? Data()
        )
        
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        print("MilitaryPayslipExtractionCoordinator: Successfully created simplified PayslipItem")
        return payslip
    }
    
    // MARK: - Private Methods
    
    private func extractName(from text: String) -> String {
        // Simple name extraction pattern
        let pattern = #"(?:Name|NAME)[\s:]+([A-Z\s]+)"#
        if let match = text.range(of: pattern, options: .regularExpression) {
            return String(text[match]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Military Personnel"
    }
    
    private func extractMonth(from text: String) -> String {
        let monthPattern = #"(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"#
        if let match = text.range(of: monthPattern, options: .regularExpression) {
            return String(text[match])
        }
        return DateFormatter().string(from: Date()).prefix(3).description
    }
    
    private func extractYear(from text: String) -> Int {
        let yearPattern = #"(20\d{2})"#
        if let match = text.range(of: yearPattern, options: .regularExpression) {
            return Int(String(text[match])) ?? Calendar.current.component(.year, from: Date())
        }
        return Calendar.current.component(.year, from: Date())
    }
    
    private func extractAccountNumber(from text: String) -> String {
        let accountPattern = #"(?:Account|A/C|Acc)[\s:]+(\d{10,16})"#
        if let match = text.range(of: accountPattern, options: .regularExpression) {
            return String(text[match])
        }
        return ""
    }
    
    private func isEarning(_ key: String) -> Bool {
        let earningKeys = ["BPAY", "DA", "DP", "HRA", "TA", "MISC", "CEA", "TPT", "MSP"]
        return earningKeys.contains(key.uppercased())
    }
} 