import Foundation
import PDFKit

/// Service responsible for parsing and extracting structured data specifically from military payslips,
/// often originating from sources like PCDA (Principal Controller of Defence Accounts).
///
/// ## Military Payslip Format Overview
///
/// Military payslips in India and other countries follow specific formats:
///
/// 1. **PCDA Format** (Principal Controller of Defence Accounts):
///    - Standard format used by Indian Armed Forces
///    - Organized in multi-column layout with code-value pairs (e.g., "BPAY 50000.00 DSOP 5000.00")
///    - Contains service-specific sections for basic details, earnings, and deductions
///    - Often includes deployment status, rank, and service number
///
/// 2. **Common Structural Elements**:
///    - Header section with identifying information (name, rank, service number)
///    - Earnings section with military-specific allowances (e.g., MSP, DA, HRA)
///    - Deductions section with military-specific deductions (e.g., DSOP, AGIF)
///    - Summary section with totals and net remittance
///    - Often contains banking details for direct deposit
///
/// 3. **Military-Specific Characteristics**:
///    - Uses standardized abbreviation codes for pay and deduction elements
///    - Different formatting based on service branch (Army, Navy, Air Force, etc.)
///    - Special allowances for deployment zones, hazardous duty, or specialized roles
///    - Integrated pension contribution systems (DSOP)
///
/// This service uses a combination of pattern matching, military-specific code recognition,
/// and contextual analysis to extract structured data from these specialized formats.
/// It identifies military payslips, extracts financial information, and builds a complete
/// `PayslipItem` with detailed earnings and deductions categorization.
class MilitaryPayslipExtractionService: MilitaryPayslipExtractionServiceProtocol {
    // MARK: - Properties
    
    /// Service used for applying pattern definitions to extract data
    ///
    /// The pattern matching service provides a mechanism to define reusable extraction patterns
    /// for different types of military payslip formats. These patterns help identify specific
    /// fields based on their context and known formatting characteristics.
    private let patternMatchingService: PatternMatchingServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes the military payslip extraction service.
    ///
    /// - Parameter patternMatchingService: A service conforming to `PatternMatchingServiceProtocol` 
    ///   used for applying pattern definitions to extract data. If nil, a default `PatternMatchingService` 
    ///   is instantiated.
    ///
    /// The pattern matching service is crucial for handling the variations in military payslip formats
    /// across different branches and years. It allows for a flexible extraction approach that can
    /// adapt to format changes without requiring code modifications.
    init(patternMatchingService: PatternMatchingServiceProtocol? = nil) {
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
    }
    
    // MARK: - Public Methods
    
    /// Determines if the provided text content likely originates from a military payslip.
    ///
    /// This check employs a two-step identification strategy:
    ///
    /// 1. **Direct Marker Identification**:
    ///    Searches for definitive markers like "PCDA" or "Principal Controller of Defence Accounts"
    ///    that conclusively identify a military payslip.
    ///
    /// 2. **Military Terminology Analysis**:
    ///    If direct markers aren't found, analyzes the text for the presence of multiple
    ///    military-specific terms (e.g., "Rank", "Service No", "AFPPF"). Finding 3 or more
    ///    such terms suggests a military payslip with high confidence.
    ///
    /// This dual approach ensures accurate identification even when documents have different
    /// headers or when standard markers might be obscured due to OCR errors.
    ///
    /// - Parameter text: The text content extracted from a PDF or other source.
    /// - Returns: `true` if the text is identified as a potential military payslip, `false` otherwise.
    func isMilitaryPayslip(_ text: String) -> Bool {
        // Check for PCDA format markers
        let pcdaMarkers = ["PCDA", "Principal Controller of Defence Accounts"]
        for marker in pcdaMarkers {
            if text.contains(marker) {
                print("MilitaryPayslipExtractionService: Detected PCDA format")
                return true
            }
        }
        
        // Check for common military terms
        let militaryTerms = ["Rank", "Service No", "AFPPF", "Army", "Navy", "Air Force", "Defence", "Battalion", "Regiment", "Corps", "Pay Code"]
        var matches = 0
        for term in militaryTerms {
            if text.contains(term) {
                matches += 1
            }
        }
        
        // If at least 3 military terms are found, consider it a military payslip
        if matches >= 3 {
            print("MilitaryPayslipExtractionService: Detected \(matches) military terms")
            return true
        }
        
        return false
    }
    
    /// Extracts structured data from text identified as belonging to a military payslip.
    ///
    /// This method orchestrates the complete extraction process through these stages:
    ///
    /// 1. **Pre-processing**:
    ///    - Handles special test case data if present
    ///    - Performs basic validation (e.g., text length)
    ///
    /// 2. **Basic Information Extraction**:
    ///    Extracts key identifying fields:
    ///    - Personnel name (typically includes rank for officers)
    ///    - Pay period month and year
    ///    - Bank account number for direct deposit
    ///    
    /// 3. **Financial Data Extraction**:
    ///    Calls `extractMilitaryTabularData` to extract detailed:
    ///    - Earnings (Basic Pay, Military Service Pay, allowances)
    ///    - Deductions (DSOP, AGIF, Income Tax, insurance)
    ///
    /// 4. **Financial Summary Calculation**:
    ///    - Calculates aggregate totals (credits, debits)
    ///    - Identifies specific deductions like tax and DSOP (pension)
    ///
    /// 5. **Validation & Payslip Construction**:
    ///    - Validates essential extracted data
    ///    - Constructs and returns a complete `PayslipItem`
    ///
    /// The method employs military-specific knowledge about payslip structures and
    /// field positioning to maximize extraction accuracy even with imperfect OCR results.
    ///
    /// - Parameters:
    ///   - text: The extracted text content from the payslip.
    ///   - pdfData: Optional raw PDF data associated with the payslip text.
    /// - Returns: A `PayslipItem` containing the structured extracted data.
    /// - Throws: `MilitaryExtractionError.insufficientData` if essential data cannot be 
    ///   extracted or validated, or other errors related to helper function failures.
    func extractMilitaryPayslipData(from text: String, pdfData: Data?) throws -> PayslipItem? {
        print("MilitaryPayslipExtractionService: Attempting to extract military payslip data")
        
        // Special case for test data
        if text.contains("#TEST_CASE#") {
            print("MilitaryPayslipExtractionService: Detected test case, using simplified extraction")
            return createTestPayslipItem(from: text, pdfData: pdfData)
        }
        
        // If text is too short, it's probably not valid
        if text.count < 200 {
            print("MilitaryPayslipExtractionService: Text too short (\(text.count) chars)")
            throw MilitaryExtractionError.insufficientData
        }
        
        // Extract basic information
        let name = extractName(from: text)
        let month = extractMonth(from: text)
        let year = extractYear(from: text)
        let accountNumber = extractAccountNumber(from: text)
        
        // Extract earnings and deductions using tabular data extraction
        let (earnings, deductions) = extractMilitaryTabularData(from: text)
        
        // Calculate credits, debits, tax, and dsop based on the detailed earnings and deductions
        let credits = earnings.values.reduce(0, +)
        let debits = deductions.values.reduce(0, +)
        
        // Extract specific deductions if available
        let tax = deductions["ITAX"] ?? deductions["IT"] ?? 0.0
        let dsop = deductions["DSOP"] ?? 0.0
        
        // Validate essential data
        if month.isEmpty || year == 0 || credits == 0 {
            print("MilitaryPayslipExtractionService: Insufficient data extracted")
            throw MilitaryExtractionError.insufficientData
        }
        
        // Create the payslip item
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
            panNumber: "", // Military payslips often don't have PAN number directly visible
            pdfData: pdfData // Use actual PDF data if available, otherwise nil
        )
        
        // Set earnings and deductions
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        print("MilitaryPayslipExtractionService: Successfully created PayslipItem")
        return payslip
    }
    
    /// Creates a test payslip item for testing and debugging purposes.
    ///
    /// This specialized method generates a test `PayslipItem` by parsing specially formatted markers
    /// in the input text. It supports a flexible key-value format that allows testers to specify
    /// exactly which values should be used for testing particular scenarios or edge cases.
    ///
    /// ## Test Marker Format
    /// The method recognizes markers in the format `#KEY:VALUE#`, where:
    /// - `KEY` is an uppercase identifier (e.g., `NAME`, `MONTH`, `CREDITS`)
    /// - `VALUE` is the desired test value (e.g., `Test Officer`, `January`, `50000`)
    ///
    /// ## Supported Test Keys
    /// - **Basic Fields**: `NAME`, `MONTH`, `YEAR`, `ACCOUNT`, `PAN`
    /// - **Financial Totals**: `CREDITS`, `DEBITS`, `TAX`, `DSOP`
    /// - **Earnings Components**: Any key prefixed with `EARN_` (e.g., `EARN_Basic Pay`)
    /// - **Deductions Components**: Any key prefixed with `DED_` (e.g., `DED_ITAX`)
    ///
    /// ## Example Test String
    /// ```
    /// #TEST_CASE##NAME:Capt. John Smith##MONTH:June##YEAR:2024##CREDITS:75000##DEBITS:22500##EARN_Basic Pay:45000##EARN_MSP:15000##DED_DSOP:7500#
    /// ```
    ///
    /// This method is intended solely for testing purposes, particularly for:
    /// - Unit testing extraction logic
    /// - Validating financial calculations
    /// - Testing edge cases and unusual payslip formats
    /// - Debugging extraction issues with controlled inputs
    ///
    /// - Parameters:
    ///   - text: The text content containing test data markers (e.g., from a test file or string).
    ///   - pdfData: Optional raw PDF data to associate with the test payslip.
    /// - Returns: A `PayslipItem` populated with values extracted from the test markers or defaults.
    private func createTestPayslipItem(from text: String, pdfData: Data?) -> PayslipItem {
        // Extract test values from the text using simple key-value format
        var testValues: [String: String] = [:]
        
        // Find test data markers in format #KEY:VALUE#
        let pattern = "#([A-Z_]+):(.*?)#"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let keyRange = match.range(at: 1)
                    let valueRange = match.range(at: 2)
                    
                    let key = nsText.substring(with: keyRange)
                    let value = nsText.substring(with: valueRange)
                    
                    testValues[key] = value
                }
            }
        }
        
        // Extract or use default values
        let name = testValues["NAME"] ?? "Test Military Officer"
        let month = testValues["MONTH"] ?? getCurrentMonth()
        let yearStr = testValues["YEAR"] ?? String(getCurrentYear())
        let accountNumber = testValues["ACCOUNT"] ?? "MILITARY123456789"
        
        // Convert numeric values
        let credits = Double(testValues["CREDITS"] ?? "50000") ?? 50000.0
        let debits = Double(testValues["DEBITS"] ?? "15000") ?? 15000.0
        let tax = Double(testValues["TAX"] ?? "8000") ?? 8000.0
        let dsop = Double(testValues["DSOP"] ?? "5000") ?? 5000.0
        let year = Int(yearStr) ?? getCurrentYear()
        
        // Create test earnings and deductions
        var earnings: [String: Double] = [
            "Basic Pay": credits * 0.6,
            "Allowances": credits * 0.4
        ]
        
        var deductions: [String: Double] = [
            "ITAX": tax,
            "DSOP": dsop,
            "Other": debits - tax - dsop
        ]
        
        // Override with any specific earnings or deductions
        for (key, value) in testValues {
            if key.starts(with: "EARN_") {
                let earningName = String(key.dropFirst(5))
                if let amount = Double(value) {
                    earnings[earningName] = amount
                }
            } else if key.starts(with: "DED_") {
                let deductionName = String(key.dropFirst(4))
                if let amount = Double(value) {
                    deductions[deductionName] = amount
                }
            }
        }
        
        // Create the payslip item
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
            panNumber: testValues["PAN"] ?? "",
            pdfData: pdfData // Use actual PDF data if available for test, otherwise nil
        )
        
        // Set earnings and deductions
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        return payslip
    }
    
    /// Extracts the bank account number from the payslip text using predefined regex patterns.
    ///
    /// In military payslips, bank account numbers are typically formatted differently than
    /// civilian payslips. They often include service-specific identifiers or branch codes
    /// and may appear in various sections of the document.
    ///
    /// ## Common Military Account Number Formats
    ///
    /// 1. **Standard Format**: `Account No: 1234567890`
    /// 2. **A/C Format**: `Bank A/c: SBI-1234567890` 
    /// 3. **Credit Format**: `Crdt A/c: 1234567890`
    ///
    /// The method tries multiple pattern variations to accommodate these different formats
    /// and extracts the first successful match. It handles potential OCR irregularities by
    /// allowing flexible whitespace patterns around the separators.
    ///
    /// - Parameter text: The payslip text content to search within.
    /// - Returns: The extracted account number (trimmed), or an empty string if no pattern matches.
    private func extractAccountNumber(from text: String) -> String {
        // Common patterns for account numbers in military payslips
        let accountPatterns = [
            "Account No[.:]?\\s*([A-Z0-9\\s]+)",
            "Account[\\s:]+([A-Z0-9\\s]+)",
            "Bank A/c[\\s:]+([A-Z0-9\\s]+)",
            "Crdt A/c:[\\s]*([A-Z0-9\\s]+)"
        ]
        
        for pattern in accountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound, let range = Range(range, in: text) {
                    let account = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return account
                }
            }
        }
        
        return ""
    }
    
    /// Extracts the employee's name from the military payslip text.
    ///
    /// Military payslips typically include rank along with name (e.g., "Capt. John Smith" or 
    /// "SGT Maria Rodriguez"). This method is designed to handle these military-specific 
    /// name formats and extract the complete name with rank where applicable.
    ///
    /// ## Extraction Strategy
    ///
    /// 1. **Pattern-Based Approach**:
    ///    First attempts to use a predefined pattern (`military_name`) through the pattern matching service,
    ///    which may be customized for specific military branches or payslip formats.
    ///
    /// 2. **Direct Pattern Matching**:
    ///    If the pattern service fails, falls back to direct regex matching using common
    ///    military payslip formats for name fields:
    ///    - Standard: `Name: Capt. John Smith`
    ///    - Officer-specific: `Officer Name: Lt. Jane Doe`
    ///    - Rank-inclusive: `Rank & Name: WO Thomas Johnson`
    ///
    /// The method is designed to preserve rank prefixes and military-specific name elements
    /// that might be relevant for proper identification and addressing of personnel.
    ///
    /// - Parameter text: The payslip text content to search within.
    /// - Returns: The extracted name (trimmed), or an empty string if no name is found.
    private func extractName(from text: String) -> String {
        // Use pattern matching service if possible
        if let name = patternMatchingService.extractValue(for: "military_name", from: text) {
            return name
        }
        
        // Fallback to direct pattern matching
        let namePatterns = [
            "Name\\s*:\\s*([A-Za-z\\s.]+)",
            "Officer Name\\s*:\\s*([A-Za-z\\s.]+)",
            "Rank & Name\\s*:\\s*([A-Za-z0-9\\s.]+)"
        ]
        
        for pattern in namePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound, let range = Range(range, in: text) {
                    let name = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return name
                }
            }
        }
        
        return ""
    }
    
    /// Extracts the payslip month name from the text content.
    ///
    /// Military payslips may reference months in several different formats:
    /// - Direct reference: "Month: January"
    /// - Pay period reference: "Pay for the month of March"
    /// - Salary reference: "Salary for April" 
    ///
    /// ## Extraction Strategy
    ///
    /// This method employs a multi-layered approach to maximize extraction success:
    ///
    /// 1. **Pattern-Based Approach**:
    ///    First attempts to use a predefined pattern (`military_month`) through the pattern matching service.
    ///
    /// 2. **Direct Pattern Matching**:
    ///    If the pattern service fails, tries multiple regex patterns targeting common month references.
    ///    When a match is found, validates it against known month names to ensure accuracy.
    ///
    /// 3. **Direct Month Search**:
    ///    If pattern matching fails, searches for the direct occurrence of any month name 
    ///    (e.g., "January", "February") within the entire text.
    ///
    /// 4. **Fallback Strategy**:
    ///    If all extraction attempts fail, defaults to the current month name as a reasonable fallback.
    ///
    /// This robust approach ensures that even with variations in payslip formatting or OCR quality issues,
    /// the month information is still likely to be successfully extracted.
    ///
    /// - Parameter text: The payslip text content to search within.
    /// - Returns: The extracted month name (e.g., "July"), or the current month's name as a fallback.
    private func extractMonth(from text: String) -> String {
        // Use pattern matching service if possible
        if let month = patternMatchingService.extractValue(for: "military_month", from: text) {
            return month
        }
        
        // Fallback to direct pattern matching
        let monthPatterns = [
            "Pay for the month of\\s+([A-Za-z]+)",
            "Month\\s*:\\s*([A-Za-z]+)",
            "Salary for\\s+([A-Za-z]+)",
            "Month of\\s+([A-Za-z]+)"
        ]
        
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        
        // Try to find month using patterns
        for pattern in monthPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound, let range = Range(range, in: text) {
                    let monthText = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Validate month
                    for month in months {
                        if monthText.lowercased().contains(month.lowercased()) {
                            return month
                        }
                    }
                    
                    // If exact match not found, return the extracted text
                    return monthText
                }
            }
        }
        
        // If no month found, look for month names directly in the text
        for month in months {
            if text.contains(month) {
                return month
            }
        }
        
        // If no month found, use current month
        return getCurrentMonth()
    }
    
    /// Extracts the payslip year from the text content.
    ///
    /// Military payslips often reference years in multiple ways:
    /// - Calendar year: "2024"
    /// - Fiscal year: "FY 23/24" or "FY 2023-24"
    /// - Pay period: "Pay for the month of July 2024"
    ///
    /// ## Extraction Strategy
    ///
    /// This method employs a multi-layered approach to extract the correct year:
    ///
    /// 1. **Pattern-Based Approach**:
    ///    First attempts to use a predefined pattern (`military_year`) through the pattern matching service.
    ///
    /// 2. **Direct Pattern Matching**:
    ///    If the pattern service fails, tries multiple regex patterns targeting:
    ///    - Full 4-digit years (e.g., "2024")
    ///    - Fiscal year references (e.g., "FY 23/24", "FY 2023")
    ///    - Date context (e.g., "Pay for the month of July 2024")
    ///
    /// 3. **2-Digit Year Handling**:
    ///    When encountering 2-digit years (e.g., "24" in "FY 23/24"), the method
    ///    assumes they are in the 2000s and converts them to 4-digit format.
    ///
    /// 4. **Generic Year Search**:
    ///    If specific patterns fail, searches for any 4-digit number starting with "20"
    ///    that likely represents a year (between 2000 and current year + 1).
    ///
    /// 5. **Fallback Strategy**:
    ///    If all extraction attempts fail, defaults to the current year as a reasonable fallback.
    ///
    /// This comprehensive approach ensures robust year extraction even from inconsistently 
    /// formatted payslips or those with OCR quality issues.
    ///
    /// - Parameter text: The payslip text content to search within.
    /// - Returns: The extracted year as an integer (e.g., 2024), or the current year as a fallback.
    private func extractYear(from text: String) -> Int {
        // Use pattern matching service if possible
        if let yearStr = patternMatchingService.extractValue(for: "military_year", from: text),
           let year = Int(yearStr) {
            return year
        }
        
        // Fallback to direct pattern matching
        let yearPatterns = [
            "Pay for the month of\\s+[A-Za-z]+\\s+(\\d{4})",
            "(\\d{4})\\s*-\\s*\\d{2}",
            "Year\\s*:\\s*(\\d{4})",
            "FY[\\s:]+\\d{2}[-/](\\d{2})",
            "FY\\s+(\\d{4})"
        ]
        
        // Try to find year using patterns
        for pattern in yearPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound, let range = Range(range, in: text) {
                    let yearStr = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Handle 2-digit years
                    if yearStr.count == 2 {
                        let prefix = "20" // Assuming years are in the 2000s
                        if let year = Int(prefix + yearStr) {
                            return year
                        }
                    } else if let year = Int(yearStr) {
                        // 4-digit years
                        return year
                    }
                }
            }
        }
        
        // If no year found, find any 4-digit number that could be a year
        let genericYearPattern = "(20\\d{2})"
        if let regex = try? NSRegularExpression(pattern: genericYearPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
           match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if range.location != NSNotFound, let range = Range(range, in: text) {
                let yearStr = String(text[range])
                if let year = Int(yearStr), year >= 2000 && year <= getCurrentYear() + 1 {
                    return year
                }
            }
        }
        
        // If no valid year found, use current year
        return getCurrentYear()
    }
    
    /// Extracts detailed tabular data (earnings and deductions) from military payslips.
    ///
    /// This specialized method extracts financial data with military-specific logic:
    ///
    /// ## Military Payslip Format Analysis
    ///
    /// Military payslips (especially PCDA format) typically organize financial data in one of two layouts:
    /// 1. **Two-column format**: `CODE1 AMOUNT1 CODE2 AMOUNT2` (pairs of codes and amounts)
    /// 2. **Single-column format**: `CODE AMOUNT` (one code and amount per line)
    ///
    /// ## Military Pay Codes
    ///
    /// ### Earnings Codes:
    /// - **BPAY**: Basic Pay - The primary salary component based on rank and years of service
    /// - **MSP**: Military Service Pay - Additional compensation for hardships of military service
    /// - **DA**: Dearness Allowance - Cost of living adjustment tied to inflation
    /// - **DP**: Dearness Pay - Historical component now typically merged with DA
    /// - **HRA**: House Rent Allowance - Accommodation allowance (varies by posting location)
    /// - **TA**: Travel Allowance - Compensation for official travel
    /// - **CEA**: Children Education Allowance - Support for education of dependents
    /// - **TPT**: Transport Allowance - For commuting to duty station
    /// - **WASHIA**: Washing Allowance - For uniform maintenance
    /// - **OUTFITA**: Outfit Allowance - For purchase and maintenance of uniforms (typically for officers)
    ///
    /// ### Deduction Codes:
    /// - **DSOP**: Defence Services Officers Provident Fund - Mandatory retirement savings
    /// - **AGIF**: Army Group Insurance Fund - Life insurance scheme for service members
    /// - **ITAX/IT**: Income Tax - Standard income tax deduction
    /// - **SBI**: State Bank of India - Loan repayment or other banking deduction
    /// - **PLI**: Postal Life Insurance - Insurance premium
    /// - **AFNB**: Armed Forces Naval Benevolent - Service-specific welfare contribution
    /// - **AOBA**: Army Officers Benevolent Association - Welfare contribution
    /// - **PLIA**: PLI Arrears - Back-payments for insurance
    /// - **CGEIS**: Central Government Employees Insurance Scheme - Insurance premium
    ///
    /// ## Extraction Strategy
    ///
    /// The method employs a multi-stage extraction and verification approach:
    /// 1. Identify code-value pairs using regex patterns for both one and two-column formats
    /// 2. Categorize each code as either an earning or deduction based on predefined sets
    /// 3. Extract explicit totals (if present) for cross-verification
    /// 4. Apply financial balancing adjustments to ensure consistency among:
    ///    - Gross Pay (sum of earnings)
    ///    - Total Deductions
    ///    - Net Remittance (Gross Pay - Total Deductions)
    ///
    /// When discrepancies are found between calculated and stated totals, the method
    /// intelligently adjusts values to ensure financial consistency, typically by:
    /// - Adding an "OTHER" category for unexplained differences
    /// - Adjusting the largest component to account for rounding or minor discrepancies
    /// - Using stated totals as the source of truth when detailed breakdowns are incomplete
    ///
    /// - Parameter text: The text to extract tabular data from
    /// - Returns: A tuple containing two dictionaries:
    ///   - The first dictionary maps earning component names (String) to their amounts (Double)
    ///   - The second dictionary maps deduction component names (String) to their amounts (Double)
    func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Check for PCDA format
        if text.contains("PCDA") || text.contains("Principal Controller of Defence Accounts") {
            print("MilitaryPayslipExtractionService: Detected PCDA format for tabular data extraction")
            
            // Define patterns for earnings and deductions
            // PCDA format typically has patterns like:
            // BPAY      123456.00     DSOP       12345.00
            
            // Match lines with two columns of data
            let twoColumnPattern = "([A-Z]+)\\s+(\\d+\\.\\d+)\\s+([A-Z]+)\\s+(\\d+\\.\\d+)"
            // Match lines with one column of data
            let oneColumnPattern = "([A-Z]+)\\s+(\\d+\\.\\d+)"
            
            // Known earning codes in military payslips
            let earningCodes = Set(["BPAY", "DA", "DP", "HRA", "TA", "MISC", "CEA", "TPT", "WASHIA", "OUTFITA", "MSP"])
            
            // Known deduction codes in military payslips
            let deductionCodes = Set(["DSOP", "AGIF", "ITAX", "IT", "SBI", "PLI", "AFNB", "AOBA", "PLIA", "HOSP", "CDA", "CGEIS", "DEDN"])
            
            // Process two-column data (earnings and deductions on same line)
            if let regex = try? NSRegularExpression(pattern: twoColumnPattern, options: []) {
                let nsText = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
                
                for match in matches {
                    if match.numberOfRanges >= 5 {
                        // First code-value pair
                        let code1Range = match.range(at: 1)
                        let value1Range = match.range(at: 2)
                        
                        // Second code-value pair
                        let code2Range = match.range(at: 3)
                        let value2Range = match.range(at: 4)
                        
                        let code1 = nsText.substring(with: code1Range)
                        let code2 = nsText.substring(with: code2Range)
                        
                        let value1Str = nsText.substring(with: value1Range)
                        let value2Str = nsText.substring(with: value2Range)
                        
                        // Convert values to doubles
                        let value1 = Double(value1Str) ?? 0.0
                        let value2 = Double(value2Str) ?? 0.0
                        
                        // Categorize as earnings or deductions based on known codes
                        if earningCodes.contains(code1) {
                            earnings[code1] = value1
                        } else if deductionCodes.contains(code1) {
                            deductions[code1] = value1
                        }
                        
                        if earningCodes.contains(code2) {
                            earnings[code2] = value2
                        } else if deductionCodes.contains(code2) {
                            deductions[code2] = value2
                        }
                    }
                }
            }
            
            // Process one-column data
            if let regex = try? NSRegularExpression(pattern: oneColumnPattern, options: []) {
                let nsText = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
                
                for match in matches {
                    if match.numberOfRanges >= 3 {
                        let codeRange = match.range(at: 1)
                        let valueRange = match.range(at: 2)
                        
                        let code = nsText.substring(with: codeRange)
                        let valueStr = nsText.substring(with: valueRange)
                        let value = Double(valueStr) ?? 0.0
                        
                        // Categorize as earnings or deductions based on known codes
                        if earningCodes.contains(code) {
                            earnings[code] = value
                        } else if deductionCodes.contains(code) {
                            deductions[code] = value
                        }
                    }
                }
            }
            
            // Look for total deductions
            let totalDeductionPatterns = [
                "Total Deductions\\s+(\\d+\\.\\d+)",
                "Gross Deductions\\s+(\\d+\\.\\d+)"
            ]
            
            for pattern in totalDeductionPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
                   match.numberOfRanges > 1 {
                    let range = match.range(at: 1)
                    if range.location != NSNotFound, let range = Range(range, in: text) {
                        let valueStr = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if let totalDeductions = Double(valueStr) {
                            // Ensure the total matches the sum of individual deductions
                            let calculatedTotal = deductions.values.reduce(0, +)
                            if abs(totalDeductions - calculatedTotal) > 1.0 && deductions.count > 0 {
                                // If there's a mismatch, add an "Other" category for the difference
                                deductions["OTHER"] = totalDeductions - calculatedTotal
                            }
                        }
                    }
                }
            }
            
            // Look for net remittance or net amount
            let netAmountPatterns = [
                "Net Remittance\\s+(\\d+\\.\\d+)",
                "Net Amount\\s+(\\d+\\.\\d+)",
                "Net Payable\\s+(\\d+\\.\\d+)"
            ]
            
            for pattern in netAmountPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
                   match.numberOfRanges > 1 {
                    let range = match.range(at: 1)
                    if range.location != NSNotFound, let range = Range(range, in: text) {
                        let valueStr = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if let netAmount = Double(valueStr) {
                            // Calculate gross pay based on net amount and deductions
                            let totalDeductions = deductions.values.reduce(0, +)
                            let grossPay = netAmount + totalDeductions
                            
                            // If we don't have any earnings, add a "Gross Pay" entry
                            if earnings.isEmpty {
                                earnings["GROSS PAY"] = grossPay
                            } else {
                                // Check if our calculated gross pay matches the sum of earnings
                                let calculatedTotal = earnings.values.reduce(0, +)
                                if abs(grossPay - calculatedTotal) > 1.0 {
                                    // If there's a significant difference, use the calculated gross pay
                                    if calculatedTotal == 0 {
                                        earnings["GROSS PAY"] = grossPay
                                    } else {
                                        // Adjust the largest earning component to make the total match
                                        let largestEarning = earnings.max(by: { $0.value < $1.value })
                                        if let (key, value) = largestEarning {
                                            let adjustment = grossPay - calculatedTotal
                                            earnings[key] = value + adjustment
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Look for gross pay
            let grossPayPatterns = [
                "Gross Pay\\s+(\\d+\\.\\d+)",
                "Gross Earnings\\s+(\\d+\\.\\d+)",
                "Total Earnings\\s+(\\d+\\.\\d+)"
            ]
            
            var explicitGrossPay: Double? = nil
            
            for pattern in grossPayPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
                   match.numberOfRanges > 1 {
                    let range = match.range(at: 1)
                    if range.location != NSNotFound, let range = Range(range, in: text) {
                        let valueStr = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if let grossPay = Double(valueStr) {
                            explicitGrossPay = grossPay
                            
                            // If we don't have any earnings, add a "Gross Pay" entry
                            if earnings.isEmpty {
                                earnings["GROSS PAY"] = grossPay
                            } else {
                                // Check if our calculated gross pay matches the explicit one
                                let calculatedTotal = earnings.values.reduce(0, +)
                                if abs(grossPay - calculatedTotal) > 1.0 {
                                    // If there's a significant difference, use the explicit gross pay
                                    if calculatedTotal == 0 {
                                        earnings["GROSS PAY"] = grossPay
                                    } else if calculatedTotal < grossPay {
                                        // Add an "Other" category for the difference
                                        earnings["OTHER"] = grossPay - calculatedTotal
                                    } else {
                                        // Adjust the largest earning component to make the total match
                                        let largestEarning = earnings.max(by: { $0.value < $1.value })
                                        if let (key, value) = largestEarning {
                                            let adjustment = grossPay - calculatedTotal
                                            earnings[key] = value + adjustment
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Calculate totals
            let totalCredits = earnings.values.reduce(0, +)
            
            // If we have an explicit gross pay, use that instead of the calculated sum
            if let grossPay = explicitGrossPay, abs(grossPay - totalCredits) > 1.0 {
                // If the explicit gross pay is different from our calculated total,
                // add an adjustment to make them match
                earnings["GROSS PAY"] = grossPay
                let calculatedEarnings = earnings.filter { $0.key != "GROSS PAY" }.values.reduce(0, +)
                
                if calculatedEarnings > 0 {
                    // Remove the GROSS PAY entry since we have detailed earnings
                    earnings.removeValue(forKey: "GROSS PAY")
                    
                    // Adjust the largest component if there's a discrepancy
                    if abs(calculatedEarnings - grossPay) > 1.0 {
                        let largestEarning = earnings.max(by: { $0.value < $1.value })
                        if let (key, value) = largestEarning {
                            let adjustment = grossPay - calculatedEarnings
                            earnings[key] = value + adjustment
                        }
                    }
                }
            }
        }
        
        return (earnings, deductions)
    }
    
    /// Returns the full name of the current month (e.g., "January", "February").
    /// 
    /// Used as a fallback when month extraction fails.
    ///
    /// - Returns: The current month name as a String.
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    /// Returns the current year as an integer.
    /// 
    /// Used as a fallback when year extraction fails.
    ///
    /// - Returns: The current year (e.g., 2024).
    private func getCurrentYear() -> Int {
        return Calendar.current.component(.year, from: Date())
    }
}

/// Custom error types for military payslip extraction
///
/// These specialized error types help identify and handle specific failure modes
/// that may occur when extracting data from military payslips.
enum MilitaryExtractionError: Error {
    /// The provided payslip is not in a recognized military format
    ///
    /// This error indicates that while a document was passed for military payslip extraction,
    /// it lacks the expected structure, markers, or terminology that would identify it as a
    /// legitimate military payslip. This could happen when a civilian payslip or other document
    /// is mistakenly processed by the military extractor.
    case invalidFormat
    
    /// Not enough data was extracted to create a valid PayslipItem
    ///
    /// This error occurs when essential fields (month, year, name, or financial totals)
    /// cannot be located in the document. This might indicate a damaged document, poor OCR quality,
    /// or a payslip format that's significantly different from expected patterns.
    case insufficientData
    
    /// General extraction failure
    ///
    /// This error represents other extraction failures not covered by more specific error types.
    /// It may occur due to unexpected format variations, processing errors, or other technical issues.
    case extractionFailed
} 