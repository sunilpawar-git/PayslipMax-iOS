import Foundation
import PDFKit

/// Unified processor for all defense personnel payslips (Army, Navy, Air Force, PCDA)
/// Refactored for architectural compliance - maintains < 300 lines using dependency injection
class UnifiedDefensePayslipProcessor: PayslipProcessorProtocol {

    // MARK: - Properties

    /// The format handled by this processor - unified defense format
    var handlesFormat: PayslipFormat {
        return .defense  // Single unified format for all defense personnel
    }

    // MARK: - Dependencies

    /// Pattern matching service for military-specific extraction patterns
    private let patternMatchingService: PatternMatchingServiceProtocol

    /// Enhanced RH12 detector for Phase 4 dual-section detection
    private let rh12Detector = EnhancedRH12Detector()

    /// Data mapper for transforming raw data to structured format
    private let dataMapper: MilitaryPayslipDataMapperProtocol

    /// Validator for data consistency checks
    private let validator: MilitaryPayslipValidatorProtocol

    /// Item builder for creating final PayslipItem
    private let itemBuilder: MilitaryPayslipItemBuilderProtocol

    /// Date extractor for military payslip dates
    private let dateExtractor: MilitaryDateExtractorProtocol

    // MARK: - Initialization

    /// Initializes a new unified defense payslip processor with dependency injection
    init(
        patternMatchingService: PatternMatchingServiceProtocol? = nil,
        dataMapper: MilitaryPayslipDataMapperProtocol? = nil,
        validator: MilitaryPayslipValidatorProtocol? = nil,
        itemBuilder: MilitaryPayslipItemBuilderProtocol? = nil,
        dateExtractor: MilitaryDateExtractorProtocol? = nil
    ) {
        self.patternMatchingService = patternMatchingService ?? PatternMatchingService()
        self.dataMapper = dataMapper ?? MilitaryPayslipDataMapper()
        self.validator = validator ?? MilitaryPayslipValidator()
        self.itemBuilder = itemBuilder ?? MilitaryPayslipItemBuilder()
        self.dateExtractor = dateExtractor ?? MilitaryDateExtractor.create()
    }

    // MARK: - PayslipProcessorProtocol Implementation

    /// Processes text from any defense personnel payslip (Army, Navy, Air Force, PCDA)
    /// Extracts defense-specific financial data using modular architecture
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[UnifiedDefensePayslipProcessor] Processing defense payslip from \(text.count) characters")

        // Validate input
        guard text.count >= 100 else {
            throw PayslipError.invalidData
        }

        // Extract financial data using dynamic patterns
        let legacyData = extractFinancialData(from: text)
        print("[UnifiedDefensePayslipProcessor] Legacy data keys: \(Array(legacyData.keys).sorted())")

        // Initialize structured data containers
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        // Map legacy data to structured format
        dataMapper.mapLegacyData(legacyData, earnings: &earnings, deductions: &deductions)

        // Enhanced RH12 Detection with cross-validation
        let rh12Instances = detectRH12Instances(from: text, legacyData: legacyData)
        dataMapper.processRH12Components(rh12Instances, earnings: &earnings, deductions: &deductions)

        // Extract date information
        let extractedDate = dateExtractor.extractStatementDate(from: text)
        print("[UnifiedDefensePayslipProcessor] Extracted date: \(extractedDate?.month ?? "UNKNOWN") \(extractedDate?.year ?? 0)")

        // Validate data consistency
        let statedCredits = legacyData["credits"] ?? 0.0
        let statedDebits = legacyData["debits"] ?? 0.0
        let (_, _) = validator.validateTotals(
            earnings: earnings,
            deductions: deductions,
            statedCredits: statedCredits,
            statedDebits: statedDebits
        )

        // Build final PayslipItem
        return try itemBuilder.buildPayslipItem(
            earnings: earnings,
            deductions: deductions,
            statedCredits: statedCredits,
            statedDebits: statedDebits,
            extractedDate: extractedDate
        )
    }

    /// Determines if this processor can handle the given text
    func canProcess(text: String) -> Double {
        let textUpper = text.uppercased()

        // Check for military/defense indicators
        let militaryIndicators = [
            "DEFENCE", "DEFENSE", "ARMY", "NAVY", "AIR FORCE", "MILITARY",
            "PCDA", "CONTROLLER OF DEFENCE ACCOUNTS", "DSOP", "AGIF",
            "BASIC PAY", "MSP", "MILITARY SERVICE PAY", "DEARNESS ALLOWANCE"
        ]

        var indicatorScore = 0.0
        for indicator in militaryIndicators {
            if textUpper.contains(indicator) {
                indicatorScore += 0.1
            }
        }

        // Additional checks for specific military payslip structures
        if textUpper.contains("PCDA") || textUpper.contains("CONTROLLER OF DEFENCE") {
            indicatorScore += 0.3
        }

        if textUpper.contains("DSOP") && textUpper.contains("AGIF") {
            indicatorScore += 0.2
        }

        return min(indicatorScore, 1.0)
    }

    // MARK: - Private Methods

    /// Extracts financial data using dynamic pattern matching
    private func extractFinancialData(from text: String) -> [String: Double] {
        print("[UnifiedDefensePayslipProcessor] Using ONLY dynamic pattern extraction to prevent false positives")

        let patternExtractor = MilitaryPatternExtractor()
        return patternExtractor.extractFinancialDataLegacy(from: text)
    }

    /// Detects RH12 instances with cross-validation to prevent false positives
    private func detectRH12Instances(from text: String, legacyData: [String: Double]) -> [(value: Double, context: String)] {
        // Extract known deductions for validation (exclude RH12 as we're detecting it)
        let knownDeductions = legacyData.filter { key, _ in
            !key.contains("RH12") && !key.contains("RH") && !key.contains("Risk") && !key.contains("Hardship")
        }.map { $0.value }

        // Get stated total for validation
        let statedTotalDeductions = legacyData["debits"] ?? 0.0

        // Use enhanced RH12 detection with cross-validation
        return rh12Detector.detectAllRH12Instances(
            in: text,
            statedDeductionsTotal: statedTotalDeductions > 0 ? statedTotalDeductions : nil,
            knownDeductions: knownDeductions
        )
    }
}

// MARK: - Factory Methods

extension UnifiedDefensePayslipProcessor {
    /// Creates processor with default dependencies for production use
    static func createDefault() -> UnifiedDefensePayslipProcessor {
        return UnifiedDefensePayslipProcessor()
    }

    /// Creates processor with custom dependencies for testing
    static func create(
        patternMatchingService: PatternMatchingServiceProtocol,
        dataMapper: MilitaryPayslipDataMapperProtocol,
        validator: MilitaryPayslipValidatorProtocol,
        itemBuilder: MilitaryPayslipItemBuilderProtocol,
        dateExtractor: MilitaryDateExtractorProtocol
    ) -> UnifiedDefensePayslipProcessor {
        return UnifiedDefensePayslipProcessor(
            patternMatchingService: patternMatchingService,
            dataMapper: dataMapper,
            validator: validator,
            itemBuilder: itemBuilder,
            dateExtractor: dateExtractor
        )
    }
}
