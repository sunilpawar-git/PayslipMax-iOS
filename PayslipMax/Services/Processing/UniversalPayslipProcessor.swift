import Foundation
import PDFKit
import os

/// Universal payslip processor using parallel search engine
/// Replaces sequential regex extraction with parallel universal search
/// Part of Phase 2: Universal Parser Migration
final class UniversalPayslipProcessor: PayslipProcessorProtocol {

    private let logger = os.Logger(subsystem: "com.payslipmax.processing", category: "UniversalParser")

    // MARK: - Properties

    /// The format handled by this processor
    var handlesFormat: PayslipFormat {
        return .defense
    }

    /// Universal search engine for parallel code extraction
    private let universalSearchEngine: UniversalPayCodeSearchEngineProtocol

    /// Classification engine for earnings/deductions determination
    private let classificationEngine: PayCodeClassificationEngine

    /// Validation coordinator for totals validation
    private let validationCoordinator: PayslipValidationCoordinatorProtocol

    /// Date extractor for military payslip date extraction
    private let dateExtractor: MilitaryDateExtractorProtocol

    // MARK: - Initialization

    init(
        universalSearchEngine: UniversalPayCodeSearchEngineProtocol? = nil,
        classificationEngine: PayCodeClassificationEngine? = nil,
        validationCoordinator: PayslipValidationCoordinatorProtocol? = nil,
        dateExtractor: MilitaryDateExtractorProtocol? = nil
    ) {
        self.universalSearchEngine = universalSearchEngine ?? UniversalPayCodeSearchEngine()
        self.classificationEngine = classificationEngine ?? PayCodeClassificationEngine()
        self.validationCoordinator = validationCoordinator ?? PayslipValidationCoordinator()
        self.dateExtractor = dateExtractor ?? MilitaryDateExtractor(
            datePatterns: DatePatternDefinitions(),
            dateValidation: DateValidationService(),
            dateProcessing: DateProcessingUtilities(),
            dateSelection: DateSelectionService(),
            confidenceCalculator: DateConfidenceCalculator()
        )
    }

    // MARK: - PayslipProcessorProtocol

    /// Processes payslip using universal search engine with anchor-based validation
    func processPayslip(from text: String) async throws -> PayslipItem {
        let startTime = Date()
        print("[UniversalPayslipProcessor] Processing with universal search engine")

        guard text.count >= 60 else {
            throw PayslipProcessingError.noText
        }

        let anchorExtractor = PayslipAnchorExtractor()
        let anchors = try extractAndValidateAnchors(from: text, extractor: anchorExtractor)
        let firstPageText = anchorExtractor.extractFirstPageText(from: text)

        let payComponents = await extractPayComponents(from: firstPageText)
        let (earnings, deductions) = classifyComponents(payComponents, anchors: anchors)

        validateTotalsAgainstAnchors(earnings: earnings, deductions: deductions, anchors: anchors)

        let (month, year) = extractDateInfo(from: firstPageText)
        let payslipItem = createPayslipItem(anchors: anchors, earnings: earnings, deductions: deductions, month: month, year: year, firstPageText: firstPageText)

        recordPerformanceMetrics(startTime: startTime, earnings: earnings, deductions: deductions, credits: anchors.grossPay, debits: anchors.totalDeductions)

        return payslipItem
    }

    /// Calculates confidence score for defense format detection
    func canProcess(text: String) -> Double {
        let score = calculateDefenseConfidence(for: text)
        logger.debug("Defense format confidence: \(String(format: "%.2f", score))")
        return score
    }

    // MARK: - Private Extraction Methods

    private func extractAndValidateAnchors(from text: String, extractor: PayslipAnchorExtractor) throws -> PayslipAnchors {
        guard var anchors = extractor.extractAnchors(from: text) ?? extractor.extractAnchors(from: text, usePreferredTopSection: false) else {
            throw PayslipProcessingError.parsingFailed
        }

        if !anchors.isEquationValid {
            let derivedAnchors = PayslipAnchors(
                grossPay: anchors.grossPay,
                totalDeductions: anchors.totalDeductions,
                netRemittance: anchors.calculatedNet,
                isNetDerived: true
            )

            if derivedAnchors.isEquationValid {
                logger.warning("Anchor equation invalid; using derived net (computed fallback)")
                anchors = derivedAnchors
            } else {
                logger.error("Anchor equation invalid — cannot derive valid net")
                throw PayslipProcessingError.invalidAnchors(anchors)
            }
        }

        logger.debug("Anchors validated — gross derived: \(anchors.isNetDerived)")
        return anchors
    }

    private func extractPayComponents(from firstPageText: String) async -> [PayComponent] {
        let searchResults = await universalSearchEngine.searchAllPayCodes(in: firstPageText)
        logger.debug("Found \(searchResults.count) components via universal search")

        var payComponents: [PayComponent] = []
        for (code, result) in searchResults {
            payComponents.append(PayComponent(code: code, amount: result.value, section: result.section))
        }

        let deduplicator = ComponentDeduplicator()
        payComponents = deduplicator.deduplicate(payComponents)
        logger.debug("After de-duplication: \(payComponents.count) components")

        logMandatoryComponentValidation(payComponents)
        return payComponents
    }

    private func logMandatoryComponentValidation(_ components: [PayComponent]) {
        let validator = DefaultMandatoryComponentValidator()
        let earningsValidation = validator.validateMandatoryEarnings(components)
        let deductionsValidation = validator.validateMandatoryDeductions(components)

        if !earningsValidation.isValid {
            logger.warning("Missing earnings components: \(earningsValidation.missingComponents.count) codes")
        }

        if !deductionsValidation.isValid {
            logger.warning("Missing deductions components: \(deductionsValidation.missingComponents.count) codes")
        }
    }

    // MARK: - Classification Methods

    private func classifyComponents(_ components: [PayComponent], anchors: PayslipAnchors) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        for component in components {
            switch component.section {
            case .earnings:
                earnings[component.code] = component.amount
            case .deductions:
                deductions[component.code] = component.amount
            case .unknown:
                classifyUnknownComponent(component, earnings: &earnings, deductions: &deductions)
            }
        }

        if anchors.isNetDerived && (earnings.count + deductions.count) < 3 {
            logger.warning("Low confidence: derived net with only \(earnings.count + deductions.count) components")
        }

        return (earnings, deductions)
    }

    private func classifyUnknownComponent(_ component: PayComponent, earnings: inout [String: Double], deductions: inout [String: Double]) {
        let classification = classificationEngine.classifyComponent(component.code)
        switch classification {
        case .guaranteedEarnings, .universalDualSection:
            earnings[component.code] = component.amount
        case .guaranteedDeductions:
            deductions[component.code] = component.amount
        }
    }

    // MARK: - Validation Methods

    private func validateTotalsAgainstAnchors(earnings: [String: Double], deductions: [String: Double], anchors: PayslipAnchors) {
        let earningsTotal = earnings.values.reduce(0, +)
        let deductionsTotal = deductions.values.reduce(0, +)

        let earningsError = anchors.grossPay > 0
            ? abs(earningsTotal - anchors.grossPay) / anchors.grossPay
            : abs(earningsTotal - anchors.grossPay)
        let deductionsError = anchors.totalDeductions > 0
            ? abs(deductionsTotal - anchors.totalDeductions) / anchors.totalDeductions
            : abs(deductionsTotal - anchors.totalDeductions)

        if earningsError > 0.05 || deductionsError > 0.05 {
            logger.warning("Totals mismatch >5% — earnings error: \(String(format: "%.1f%%", earningsError * 100)), deductions error: \(String(format: "%.1f%%", deductionsError * 100))")
        } else if earningsError > 0.01 || deductionsError > 0.01 {
            logger.warning("Totals mismatch >1% — earnings error: \(String(format: "%.1f%%", earningsError * 100)), deductions error: \(String(format: "%.1f%%", deductionsError * 100))")
        } else {
            logger.debug("Totals match anchors within 1%")
        }
    }

    // MARK: - Payslip Creation

    private func extractDateInfo(from firstPageText: String) -> (String, Int) {
        if let dateInfo = dateExtractor.extractStatementDate(from: firstPageText) {
            return (dateInfo.month, dateInfo.year)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return (dateFormatter.string(from: Date()), Calendar.current.component(.year, from: Date()))
    }

    private func createPayslipItem(anchors: PayslipAnchors, earnings: [String: Double], deductions: [String: Double], month: String, year: Int, firstPageText: String) -> PayslipItem {
        let tax = deductions["Income Tax"] ?? deductions["ITAX"] ?? deductions.first(where: { $0.key.contains("ITAX") })?.value ?? 0.0
        let dsop = deductions["DSOP"] ?? deductions.first(where: { $0.key.contains("DSOP") })?.value ?? 0.0
        let (name, accountNumber, panNumber) = dateExtractor.extractPersonalInfo(from: firstPageText)

        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: anchors.grossPay,
            debits: anchors.totalDeductions,
            dsop: dsop,
            tax: tax,
            name: name ?? "Defense Personnel",
            accountNumber: accountNumber ?? "",
            panNumber: panNumber ?? "",
            pdfData: nil
        )

        payslipItem.metadata["anchors.isNetDerived"] = anchors.isNetDerived ? "true" : "false"
        payslipItem.metadata["anchors.present"] = "true"
        payslipItem.earnings = earnings
        payslipItem.deductions = deductions

        logger.debug("Payslip created — earnings: \(earnings.count), deductions: \(deductions.count)")
        return payslipItem
    }

    private func recordPerformanceMetrics(startTime: Date, earnings: [String: Double], deductions: [String: Double], credits: Double, debits: Double) {
        let processingTime = Date().timeIntervalSince(startTime)
        ParserPerformanceMonitor.shared.recordMetrics(.init(
            processingTime: processingTime,
            componentsExtracted: earnings.count + deductions.count,
            credits: credits,
            debits: debits,
            parserType: "Universal",
            timestamp: Date()
        ))
    }

    // MARK: - Confidence Calculation

    private func calculateDefenseConfidence(for text: String) -> Double {
        let uppercaseText = text.uppercased()
        var score = 0.0

        let defenseKeywords: [String: Double] = [
            "ARMY": 0.4, "NAVY": 0.4, "AIR FORCE": 0.4,
            "INDIAN ARMY": 0.5, "INDIAN NAVY": 0.5, "INDIAN AIR FORCE": 0.5,
            "DEFENCE": 0.3, "MILITARY": 0.3, "PCDA": 0.4,
            "DSOP": 0.3, "AGIF": 0.2, "MSP": 0.2, "BASIC PAY": 0.2, "BPAY": 0.2,
            "STATEMENT OF ACCOUNT FOR MONTH ENDING": 0.4,
            "PAO": 0.3, "SUS NO": 0.3, "TASK": 0.2, "AMOUNT CREDITED TO BANK": 0.3
        ]

        for (keyword, weight) in defenseKeywords where uppercaseText.contains(keyword) {
            score += weight
        }

        return min(score, 1.0)
    }
}
