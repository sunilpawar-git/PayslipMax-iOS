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

    /// RH12 processing service for enhanced RH12 detection
    private let rh12ProcessingService: RH12ProcessingServiceProtocol

    /// Universal arrears pattern matcher for Phase 3 implementation
    private let arrearsPatternMatcher: UniversalArrearsPatternMatcherProtocol?

    /// Arrears display formatter for user-friendly names
    private let arrearsFormatter = ArrearsDisplayFormatter()

    /// Date extractor for military payslip date extraction
    private let dateExtractor: MilitaryDateExtractorProtocol

    /// Payslip validation coordinator for totals validation
    private let validationCoordinator: PayslipValidationCoordinatorProtocol
    
    /// Universal processing integrator for Phase 2 implementation
    private let universalProcessingIntegrator: UniversalProcessingIntegrator

    // MARK: - Initialization

    /// Initializes a new unified defense payslip processor
    init(patternMatchingService: PatternMatchingServiceProtocol? = nil,
         arrearsPatternMatcher: UniversalArrearsPatternMatcherProtocol? = nil,
         dateExtractor: MilitaryDateExtractorProtocol? = nil,
         rh12ProcessingService: RH12ProcessingServiceProtocol? = nil,
         validationCoordinator: PayslipValidationCoordinatorProtocol? = nil,
         universalProcessingIntegrator: UniversalProcessingIntegrator? = nil) {
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
        self.arrearsPatternMatcher = arrearsPatternMatcher
        self.dateExtractor = dateExtractor ?? MilitaryDateExtractor(
            datePatterns: DatePatternDefinitions(),
            dateValidation: DateValidationService(),
            dateProcessing: DateProcessingUtilities(),
            dateSelection: DateSelectionService(),
            confidenceCalculator: DateConfidenceCalculator()
        )
        self.rh12ProcessingService = rh12ProcessingService ?? RH12ProcessingService()
        self.validationCoordinator = validationCoordinator ?? PayslipValidationCoordinator()
        self.universalProcessingIntegrator = universalProcessingIntegrator ?? UniversalProcessingIntegrator()
    }

    // MARK: - PayslipProcessorProtocol Implementation

    /// Processes text from any defense personnel payslip (Army, Navy, Air Force, PCDA)
    /// Extracts defense-specific financial data (Basic Pay, MSP, DSOP, AGIF, HRA, DA)
    /// - Parameter text: The full text extracted from the PDF
    /// - Returns: A PayslipItem representing the processed defense payslip
    /// - Throws: An error if essential data cannot be determined
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[UnifiedDefensePayslipProcessor] Processing defense payslip from \(text.count) characters")

        guard text.count >= 100 else {
            throw PayslipError.invalidData
        }

        let patternExtractor = MilitaryPatternExtractor()
        let legacyData = patternExtractor.extractFinancialDataLegacy(from: text)
        print("[UnifiedDefensePayslipProcessor] Legacy data keys: \(Array(legacyData.keys).sorted())")

        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        // Process RH12 components using the dedicated service
        rh12ProcessingService.processRH12Components(
            from: text,
            legacyData: legacyData,
            earnings: &earnings,
            deductions: &deductions
        )

        // Map legacy data to standardized component names
        mapLegacyComponents(legacyData, to: &earnings, deductions: &deductions, text: text)

        // Process arrears components
        processArrearsComponents(from: text, legacyData: legacyData, earnings: &earnings, deductions: &deductions)

        // Extract date information
        var month = ""
        var year = Calendar.current.component(.year, from: Date())

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

        // Validate and get totals using the validation coordinator
        let (credits, debits) = validationCoordinator.validateAndGetTotals(
            earnings: earnings,
            deductions: deductions,
            legacyData: legacyData
        )

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
        let score = calculateDefenseConfidence(for: text)

        print("[UnifiedDefensePayslipProcessor] Defense format confidence score: \(score)")
        return score
    }

    // MARK: - Private Helper Methods

    /// Maps legacy extracted data to standardized earnings and deductions components
    /// Enhanced for universal dual-section processing
    private func mapLegacyComponents(_ legacyData: [String: Double],
                                   to earnings: inout [String: Double],
                                   deductions: inout [String: Double],
                                   text: String) {
        for (key, value) in legacyData {
            // Skip RH12 and arrears - handled by specialized services
            if key.contains("RH") || key.contains("ARR") {
                continue
            }
            
            // Process component using enhanced classification system
            universalProcessingIntegrator.processComponentWithClassification(
                key: key,
                value: value,
                text: text,
                earnings: &earnings,
                deductions: &deductions
            )
        }
    }
    

    /// Processes arrears components using universal system or legacy fallback
    private func processArrearsComponents(from text: String,
                                        legacyData: [String: Double],
                                        earnings: inout [String: Double],
                                        deductions: inout [String: Double]) {
        if arrearsPatternMatcher != nil {
            // Note: Universal arrears processing disabled for synchronous operation
            // TODO: Re-enable with proper async handling if needed
            print("[UnifiedMilitaryPayslipProcessor] Universal arrears system available but disabled for sync operation")
        } else {
            // Legacy fallback for arrears patterns
            for (key, value) in legacyData {
                if key.contains("ARR-CEA") {
                    earnings["Arrears CEA"] = value
                } else if key.contains("ARR-DA") {
                    earnings["Arrears DA"] = value
                } else if key.contains("ARR-TPTADA") {
                    earnings["Arrears TPTADA"] = value
                } else if key.contains("ARR-RSHNA") {
                    earnings["Arrears RSHNA"] = value
                }
            }
        }
    }

    /// Calculates confidence score for defense payslip format detection
    private func calculateDefenseConfidence(for text: String) -> Double {
        let uppercaseText = text.uppercased()
        var score = 0.0

        let defenseKeywords: [String: Double] = [
            "ARMY": 0.4, "NAVY": 0.4, "AIR FORCE": 0.4,
            "INDIAN ARMY": 0.5, "INDIAN NAVY": 0.5, "INDIAN AIR FORCE": 0.5,
            "DEFENCE": 0.3, "MILITARY": 0.3, "PCDA": 0.4,
            "PRINCIPAL CONTROLLER": 0.4, "DEFENCE ACCOUNTS": 0.4,
            "CONTROLLER OF DEFENCE ACCOUNTS": 0.5, "STATEMENT OF ACCOUNT": 0.3,
            "DSOP": 0.3, "DSOP FUND": 0.3, "AGIF": 0.2, "MSP": 0.2,
            "MILITARY SERVICE PAY": 0.3, "BPAY": 0.2, "BASIC PAY": 0.1,
            "SERVICE NO": 0.2, "RANK": 0.1
        ]

        for (keyword, weight) in defenseKeywords {
            if uppercaseText.contains(keyword) {
                score += weight
            }
        }

        let defenseIndicatorCount = ["DSOP", "MSP", "AGIF", "PCDA", "ARMY", "NAVY", "AIR FORCE"]
            .filter { uppercaseText.contains($0) }.count

        if defenseIndicatorCount >= 2 {
            score += 0.2
        }

        return min(score, 1.0)
    }
}
