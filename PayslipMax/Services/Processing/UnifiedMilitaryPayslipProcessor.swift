import Foundation
import PDFKit

/// Unified processor for all defense personnel payslips (Army, Navy, Air Force, PCDA)
/// This processor handles all formats used by Indian Armed Forces with true unified processing
class UnifiedDefensePayslipProcessor: PayslipProcessorProtocol {

    // MARK: - Properties

    /// The format handled by this processor - unified defense format
    var handlesFormat: PayslipFormat {
        return .defense  // Single unified format for all defense personnel
    }

    /// Military abbreviations service for terminology handling
    private let abbreviationsService = MilitaryAbbreviationsService.shared

    /// Pattern matching service for military-specific extraction patterns
    private let patternMatchingService: PatternMatchingServiceProtocol

    /// Section classifier for dual-section component detection
    private let sectionClassifier = PayslipSectionClassifier()

    // MARK: - Initialization

    /// Initializes a new unified defense payslip processor
    init(patternMatchingService: PatternMatchingServiceProtocol? = nil) {
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
    }

    // MARK: - PayslipProcessorProtocol Implementation

    /// Processes text from any defense personnel payslip (Army, Navy, Air Force, PCDA)
    /// Extracts defense-specific financial data (Basic Pay, MSP, DSOP, AGIF, HRA, DA)
    /// - Parameter text: The full text extracted from the PDF
    /// - Returns: A PayslipItem representing the processed defense payslip
    /// - Throws: An error if essential data cannot be determined
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[UnifiedDefensePayslipProcessor] Processing defense payslip from \(text.count) characters")

        // Validate input
        guard text.count >= 100 else {
            throw PayslipError.invalidData
        }

        // Use ONLY the new dynamic extraction system to prevent conflicts and false positives
        // OLD SYSTEM DISABLED: patternMatchingService.extractTabularData() was causing spurious entries
        let patternExtractor = MilitaryPatternExtractor()
        let legacyData = patternExtractor.extractFinancialDataLegacy(from: text)

        // Initialize with validated dynamic extraction results only
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        print("[UnifiedDefensePayslipProcessor] Using ONLY dynamic pattern extraction to prevent false positives")

        // Use validated dynamic extraction results with proper component mapping
        // All values are already pre-validated by DynamicMilitaryPatternService
        for (key, value) in legacyData {
            if key.contains("BPAY") || key.contains("BasicPay") {
                earnings["Basic Pay"] = value
            } else if key.contains("MSP") {
                earnings["Military Service Pay"] = value
            } else if key.contains("DA") && !key.contains("ARR") && !key.contains("TPTA") {
                earnings["Dearness Allowance"] = value
            } else if isRiskHardshipCode(key) {
                // All RH codes can appear in both earnings and deductions - use section context
                let sectionType = sectionClassifier.classifyRH12Section(key: key, value: value, text: text)
                if sectionType == .earnings {
                    earnings["Risk and Hardship Allowance"] = value
                } else if sectionType == .deductions {
                    deductions["Risk and Hardship Allowance"] = value
                }
            } else if key.contains("TPTA") && !key.contains("TPTADA") && !key.contains("ARR") {
                earnings["Transport Allowance"] = value
            } else if key.contains("TPTADA") && !key.contains("ARR") {
                earnings["Transport Allowance DA"] = value
            } else if key.contains("ARR-CEA") {
                earnings["Arrears CEA"] = value
            } else if key.contains("ARR-DA") {
                earnings["Arrears DA"] = value
            } else if key.contains("ARR-TPTADA") {
                earnings["Arrears TPTADA"] = value
            } else if key.contains("DSOP") {
                deductions["DSOP"] = value
            } else if key.contains("AGIF") {
                deductions["AGIF"] = value
            } else if key.contains("EHCESS") {
                deductions["EHCESS"] = value
            } else if key.contains("ITAX") || key.contains("IncomeTax") {
                deductions["Income Tax"] = value
            }
            // NOTE: HRA completely disabled as it was causing false positives
            // Dynamic validation system already prevented HRA extraction
        }

        // Extract date information
        var month = ""
        var year = Calendar.current.component(.year, from: Date())

        let dateExtractor = MilitaryDateExtractor()
        if let dateInfo = dateExtractor.extractStatementDate(from: text) {
            month = dateInfo.month
            year = dateInfo.year
            print("[UnifiedDefensePayslipProcessor] Extracted date: \(month) \(year)")
        } else {
            // Fallback to current month
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
            print("[UnifiedDefensePayslipProcessor] Using current date fallback: \(month) \(year)")
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

            print("[UnifiedDefensePayslipProcessor] Credits validation - Extracted: ₹\(extractedCredits), Stated: ₹\(statedGrossPay), Variance: \(String(format: "%.1f", creditsVariancePercent))%")

            // If variance is too high, prefer stated total and log warning
            if creditsVariancePercent > 20.0 {
                print("[UnifiedDefensePayslipProcessor] WARNING: High variance in credits extraction, using stated total")
            }
        }

        if statedTotalDeductions > 0 {
            let debitsDifference = abs(extractedDebits - statedTotalDeductions)
            let debitsVariancePercent = (debitsDifference / statedTotalDeductions) * 100

            print("[UnifiedDefensePayslipProcessor] Debits validation - Extracted: ₹\(extractedDebits), Stated: ₹\(statedTotalDeductions), Variance: \(String(format: "%.1f", debitsVariancePercent))%")

            if debitsVariancePercent > 20.0 {
                print("[UnifiedDefensePayslipProcessor] WARNING: High variance in debits extraction, using stated total")
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

        print("[UnifiedDefensePayslipProcessor] Creating defense payslip - Credits: ₹\(credits), Debits: ₹\(debits), DSOP: ₹\(dsop)")

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
    /// Unified confidence scoring for all defense formats (Army, Navy, Air Force, PCDA)
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: A confidence score between 0.0 (unlikely) and 1.0 (likely)
    func canProcess(text: String) -> Double {
        let uppercaseText = text.uppercased()
        var score = 0.0

        // Unified defense keywords combining all service branches and accounting systems
        let defenseKeywords = [
            // Service branches (high confidence)
            "ARMY": 0.4,
            "NAVY": 0.4,
            "AIR FORCE": 0.4,
            "INDIAN ARMY": 0.5,
            "INDIAN NAVY": 0.5,
            "INDIAN AIR FORCE": 0.5,
            "DEFENCE": 0.3,
            "MILITARY": 0.3,
            // PCDA and defense accounting (high confidence)
            "PCDA": 0.4,
            "PRINCIPAL CONTROLLER": 0.4,
            "DEFENCE ACCOUNTS": 0.4,
            "CONTROLLER OF DEFENCE ACCOUNTS": 0.5,
            "STATEMENT OF ACCOUNT": 0.3,
            // Defense-specific financial components (medium confidence)
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

        // Calculate score based on unified defense keywords
        for (keyword, weight) in defenseKeywords {
            if uppercaseText.contains(keyword) {
                score += weight
            }
        }

        // Bonus for multiple defense indicators
        let defenseIndicatorCount = ["DSOP", "MSP", "AGIF", "PCDA", "ARMY", "NAVY", "AIR FORCE"].filter {
            uppercaseText.contains($0)
        }.count

        if defenseIndicatorCount >= 2 {
            score += 0.2  // Bonus for multiple defense indicators
        }

        // Cap the score at 1.0
        score = min(score, 1.0)

        print("[UnifiedDefensePayslipProcessor] Defense format confidence score: \(score)")
        return score
    }
    
    // MARK: - Private Helper Methods
    
    /// Checks if the given key represents a Risk and Hardship allowance code
    /// Supports all RH codes: RH11, RH12, RH13, RH21, RH22, RH23, RH31, RH32, RH33
    /// - Parameter key: The extracted component key
    /// - Returns: True if the key represents any RH allowance code
    private func isRiskHardshipCode(_ key: String) -> Bool {
        let rhCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]
        let uppercaseKey = key.uppercased()
        
        return rhCodes.contains { rhCode in
            uppercaseKey.contains(rhCode)
        }
    }
}
