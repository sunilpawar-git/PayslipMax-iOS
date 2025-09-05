import Foundation
import PDFKit

/// Unified processor for all defense personnel payslips (Military, PCDA, Army, Navy, Air Force)
/// This processor handles all formats used by Indian Armed Forces and eliminates the need for multiple processors
class UnifiedMilitaryPayslipProcessor: PayslipProcessorProtocol {
    
    // MARK: - Properties
    
    /// The format handled by this processor - now unified for all military formats
    var handlesFormat: PayslipFormat {
        return .military  // Handles military, pcda, and all defense formats
    }
    
    /// Military abbreviations service for terminology handling
    private let abbreviationsService = MilitaryAbbreviationsService.shared
    
    /// Pattern matching service for military-specific extraction patterns  
    private let patternMatchingService: PatternMatchingServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes a new unified military payslip processor
    init(patternMatchingService: PatternMatchingServiceProtocol? = nil) {
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
    }
    
    // MARK: - PayslipProcessorProtocol Implementation
    
    /// Processes text from any defense personnel payslip (Military, PCDA, Army, Navy, Air Force)
    /// Extracts military-specific financial data (Basic Pay, MSP, DSOP, AGIF, HRA, DA)
    /// - Parameter text: The full text extracted from the PDF
    /// - Returns: A PayslipItem representing the processed military payslip
    /// - Throws: An error if essential data cannot be determined
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[UnifiedMilitaryPayslipProcessor] Processing defense payslip from \(text.count) characters")
        
        // Validate input
        guard text.count >= 100 else {
            throw PayslipError.invalidData
        }
        
        // Use both modern pattern matching and legacy extraction for comprehensive parsing
        let (modernEarnings, modernDeductions) = patternMatchingService.extractTabularData(from: text)
        let patternExtractor = MilitaryPatternExtractor()
        let legacyData = patternExtractor.extractFinancialDataLegacy(from: text)
        
        // Merge and normalize all extracted data
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Process modern pattern matching results with military abbreviation normalization
        for (key, value) in modernEarnings {
            let normalizedKey = abbreviationsService.normalizePayComponent(key)
            earnings[normalizedKey] = value
        }
        
        for (key, value) in modernDeductions {
            let normalizedKey = abbreviationsService.normalizePayComponent(key)
            deductions[normalizedKey] = value
        }
        
        // Merge with legacy extraction (legacy takes precedence for military-specific fields)
        // Apply validation to prevent false positives
        for (key, value) in legacyData {
            if key.contains("BPAY") || key.contains("BasicPay") {
                earnings["Basic Pay"] = value
            } else if key.contains("MSP") || key.contains("MilitaryServicePay") {
                earnings["Military Service Pay"] = value
            } else if key.contains("DA") || key.contains("DearnessAllowance") {
                earnings["Dearness Allowance"] = value
            } else if key.contains("RH12") {
                earnings["Risk and Hardship Allowance"] = value
            } else if key.contains("TPTA") && !key.contains("TPTADA") {
                earnings["Transport Allowance"] = value
            } else if key.contains("TPTADA") {
                earnings["Transport Allowance DA"] = value
            } else if key.contains("ARR-CEA") {
                earnings["Arrears CEA"] = value
            } else if key.contains("ARR-DA") {
                earnings["Arrears DA"] = value
            } else if key.contains("ARR-TPTADA") {
                earnings["Arrears TPTADA"] = value
            } else if key.contains("HRA") {
                // Validate HRA to prevent false positives
                let basicPay = earnings["Basic Pay"] ?? legacyData["BasicPay"] ?? 0.0
                if basicPay > 0 && value <= basicPay * 3.0 {
                    earnings["House Rent Allowance"] = value
                    print("[UnifiedMilitaryPayslipProcessor] HRA validation passed: ₹\(value) vs Basic Pay ₹\(basicPay)")
                } else {
                    print("[UnifiedMilitaryPayslipProcessor] HRA validation failed: ₹\(value) seems unrealistic vs Basic Pay ₹\(basicPay)")
                }
            } else if key.contains("DSOP") {
                deductions["DSOP"] = value
            } else if key.contains("AGIF") {
                deductions["AGIF"] = value
            } else if key.contains("EHCESS") {
                deductions["EHCESS"] = value
            } else if key.contains("ITAX") || key.contains("IncomeTax") {
                deductions["Income Tax"] = value
            }
        }
        
        // Extract date information
        var month = ""
        var year = Calendar.current.component(.year, from: Date())
        
        let dateExtractor = MilitaryDateExtractor()
        if let dateInfo = dateExtractor.extractStatementDate(from: text) {
            month = dateInfo.month
            year = dateInfo.year
            print("[UnifiedMilitaryPayslipProcessor] Extracted date: \(month) \(year)")
        } else {
            // Fallback to current month
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
            print("[UnifiedMilitaryPayslipProcessor] Using current date fallback: \(month) \(year)")
        }
        
        // Validate extraction results against stated totals
        let extractedCredits = earnings.values.reduce(0, +)
        let extractedDebits = deductions.values.reduce(0, +)
        
        // Try to find stated totals in the text for validation
        let statedGrossPay = legacyData["credits"] ?? 0.0
        let statedTotalDeductions = legacyData["debits"] ?? 0.0
        
        // Cross-validate extracted totals
        if statedGrossPay > 0 {
            let creditsDifference = abs(extractedCredits - statedGrossPay)
            let creditsVariancePercent = (creditsDifference / statedGrossPay) * 100
            
            print("[UnifiedMilitaryPayslipProcessor] Credits validation - Extracted: ₹\(extractedCredits), Stated: ₹\(statedGrossPay), Variance: \(String(format: "%.1f", creditsVariancePercent))%")
            
            // If variance is too high, prefer stated total and log warning
            if creditsVariancePercent > 20.0 {
                print("[UnifiedMilitaryPayslipProcessor] WARNING: High variance in credits extraction, using stated total")
            }
        }
        
        if statedTotalDeductions > 0 {
            let debitsDifference = abs(extractedDebits - statedTotalDeductions)
            let debitsVariancePercent = (debitsDifference / statedTotalDeductions) * 100
            
            print("[UnifiedMilitaryPayslipProcessor] Debits validation - Extracted: ₹\(extractedDebits), Stated: ₹\(statedTotalDeductions), Variance: \(String(format: "%.1f", debitsVariancePercent))%")
            
            if debitsVariancePercent > 20.0 {
                print("[UnifiedMilitaryPayslipProcessor] WARNING: High variance in debits extraction, using stated total")
            }
        }
        
        // Use validated totals (prefer stated totals if available and reasonable)
        let credits = (statedGrossPay > 0 && abs(extractedCredits - statedGrossPay) / statedGrossPay > 0.2) ? statedGrossPay : extractedCredits
        let debits = (statedTotalDeductions > 0 && abs(extractedDebits - statedTotalDeductions) / statedTotalDeductions > 0.2) ? statedTotalDeductions : extractedDebits
        
        let tax = deductions["Income Tax"] ?? deductions["ITAX"] ?? deductions["IT"] ?? 0.0
        let dsop = deductions["DSOP"] ?? 0.0
        
        // Extract personal information
        let (name, accountNumber, panNumber) = dateExtractor.extractPersonalInfo(from: text)
        let finalName = name ?? "Defense Personnel"
        let finalAccountNumber = accountNumber ?? ""
        let finalPANNumber = panNumber ?? ""
        
        print("[UnifiedMilitaryPayslipProcessor] Creating defense payslip - Credits: ₹\(credits), Debits: ₹\(debits), DSOP: ₹\(dsop)")
        
        // Create the payslip item
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: finalName,
            accountNumber: finalAccountNumber,
            panNumber: finalPANNumber,
            pdfData: nil // Will be set by the processing pipeline
        )
        
        // Set detailed earnings and deductions
        payslipItem.earnings = earnings
        payslipItem.deductions = deductions
        
        return payslipItem
    }
    
    /// Determines if the provided text represents any defense personnel payslip
    /// Unified confidence scoring for all military formats (Military, PCDA, Army, Navy, Air Force)
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: A confidence score between 0.0 (unlikely) and 1.0 (likely)
    func canProcess(text: String) -> Double {
        let uppercaseText = text.uppercased()
        var score = 0.0
        
        // Military service indicators (high confidence)
        let militaryServiceKeywords = [
            "ARMY": 0.4,
            "NAVY": 0.4,
            "AIR FORCE": 0.4,
            "INDIAN ARMY": 0.5,
            "INDIAN NAVY": 0.5,
            "INDIAN AIR FORCE": 0.5,
            "DEFENCE": 0.3,
            "MILITARY": 0.3
        ]
        
        // PCDA and defense accounting indicators (high confidence)
        let pcdaKeywords = [
            "PCDA": 0.4,
            "PRINCIPAL CONTROLLER": 0.4,
            "DEFENCE ACCOUNTS": 0.4,
            "CONTROLLER OF DEFENCE ACCOUNTS": 0.5,
            "STATEMENT OF ACCOUNT": 0.3
        ]
        
        // Military-specific financial components (medium confidence) 
        let militaryFinancialKeywords = [
            "DSOP": 0.3,
            "DSOP FUND": 0.3,
            "AGIF": 0.2,
            "MSP": 0.2,
            "MILITARY SERVICE PAY": 0.3,
            "BPAY": 0.2,
            "BASIC PAY": 0.1,  // Lower since corporate also has this
            "SERVICE NO": 0.2,
            "RANK": 0.1
        ]
        
        // Calculate score based on all keyword categories
        let allKeywords = militaryServiceKeywords.merging(pcdaKeywords) { $0 + $1 }
            .merging(militaryFinancialKeywords) { $0 + $1 }
        
        for (keyword, weight) in allKeywords {
            if uppercaseText.contains(keyword) {
                score += weight
            }
        }
        
        // Bonus for multiple military indicators
        let militaryIndicatorCount = ["DSOP", "MSP", "AGIF", "PCDA", "ARMY", "NAVY", "AIR FORCE"].filter { 
            uppercaseText.contains($0) 
        }.count
        
        if militaryIndicatorCount >= 2 {
            score += 0.2  // Bonus for multiple military indicators
        }
        
        // Cap the score at 1.0
        score = min(score, 1.0)
        
        print("[UnifiedMilitaryPayslipProcessor] Defense format confidence score: \(score)")
        return score
    }
}
