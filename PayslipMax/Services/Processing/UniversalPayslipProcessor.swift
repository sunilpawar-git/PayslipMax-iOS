import Foundation
import PDFKit

/// Universal payslip processor using parallel search engine
/// Replaces sequential regex extraction with parallel universal search
/// Part of Phase 2: Universal Parser Migration
final class UniversalPayslipProcessor: PayslipProcessorProtocol {

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
    /// - Parameter text: The full text extracted from the PDF
    /// - Returns: A PayslipItem with extracted data
    /// - Throws: PayslipError if essential data cannot be extracted
    func processPayslip(from text: String) async throws -> PayslipItem {
        let startTime = Date()
        print("[UniversalPayslipProcessor] Processing with universal search engine")

        guard text.count >= 100 else {
            throw PayslipProcessingError.noText
        }

        // NEW: Step 1 - Extract anchors (totals) from first page
        let anchorExtractor = PayslipAnchorExtractor()
        guard let anchors = anchorExtractor.extractAnchors(from: text) else {
            throw PayslipProcessingError.parsingFailed
        }

        // NEW: Step 2 - Validate anchor equation (Gross - Deductions = Net)
        guard anchors.isEquationValid else {
            print("[UniversalPayslipProcessor] ❌ Anchor equation invalid!")
            throw PayslipProcessingError.invalidAnchors(anchors)
        }

        print("[UniversalPayslipProcessor] ✅ Anchors validated - Gross: ₹\(anchors.grossPay), Deductions: ₹\(anchors.totalDeductions), Net: ₹\(anchors.netRemittance)")

        // NEW: Step 3 - Extract first page only for component search
        let firstPageText = anchorExtractor.extractFirstPageText(from: text)

        // Step 4: Universal search (parallel extraction) on first page only
        let searchResults = await universalSearchEngine.searchAllPayCodes(in: firstPageText)
        print("[UniversalPayslipProcessor] Found \(searchResults.count) components via universal search")

        // Step 5: Convert search results to PayComponent array
        var payComponents: [PayComponent] = []
        for (code, result) in searchResults {
            let component = PayComponent(
                code: code,
                amount: result.value,
                section: result.section
            )
            payComponents.append(component)
        }

        // NEW: Step 6 - De-duplicate components
        let deduplicator = ComponentDeduplicator()
        payComponents = deduplicator.deduplicate(payComponents)
        print("[UniversalPayslipProcessor] After de-duplication: \(payComponents.count) components")

        // NEW: Step 7 - Validate mandatory components
        let validator = DefaultMandatoryComponentValidator()
        let earningsValidation = validator.validateMandatoryEarnings(payComponents)
        let deductionsValidation = validator.validateMandatoryDeductions(payComponents)

        if !earningsValidation.isValid {
            print("[UniversalPayslipProcessor] ⚠️ Missing earnings: \(earningsValidation.missingComponents.joined(separator: ", "))")
            // Don't throw, just warn for now
        }

        if !deductionsValidation.isValid {
            print("[UniversalPayslipProcessor] ⚠️ Missing deductions: \(deductionsValidation.missingComponents.joined(separator: ", "))")
            // Don't throw, just warn for now
        }

        // Step 8: Classify into earnings/deductions dictionaries
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        for component in payComponents {
            switch component.section {
            case .earnings:
                earnings[component.code] = component.amount
                print("[UniversalPayslipProcessor] \(component.code) = ₹\(component.amount) → EARNINGS")
            case .deductions:
                deductions[component.code] = component.amount
                print("[UniversalPayslipProcessor] \(component.code) = ₹\(component.amount) → DEDUCTIONS")
            case .unknown:
                // Fall back to classification engine for unknown sections
                let classification = classificationEngine.classifyComponent(component.code)
                switch classification {
                case .guaranteedEarnings, .universalDualSection:
                    earnings[component.code] = component.amount
                    print("[UniversalPayslipProcessor] \(component.code) = ₹\(component.amount) → EARNINGS (classification)")
                case .guaranteedDeductions:
                    deductions[component.code] = component.amount
                    print("[UniversalPayslipProcessor] \(component.code) = ₹\(component.amount) → DEDUCTIONS (classification)")
                }
            }
        }

        // NEW: Step 9 - Validate totals against anchors
        let earningsTotal = earnings.values.reduce(0, +)
        let deductionsTotal = deductions.values.reduce(0, +)

        let earningsDiff = abs(earningsTotal - anchors.grossPay)
        let deductionsDiff = abs(deductionsTotal - anchors.totalDeductions)

        let earningsError = earningsDiff / anchors.grossPay
        let deductionsError = deductionsDiff / anchors.totalDeductions

        if earningsError > 0.05 || deductionsError > 0.05 {
            print("[UniversalPayslipProcessor] ❌ Totals mismatch > 5%!")
            print("[UniversalPayslipProcessor]   Earnings: ₹\(earningsTotal) vs ₹\(anchors.grossPay) (\(String(format: "%.1f%%", earningsError * 100)))")
            print("[UniversalPayslipProcessor]   Deductions: ₹\(deductionsTotal) vs ₹\(anchors.totalDeductions) (\(String(format: "%.1f%%", deductionsError * 100)))")
            // For now, warn but continue
        } else if earningsError > 0.01 || deductionsError > 0.01 {
            print("[UniversalPayslipProcessor] ⚠️ Totals mismatch > 1%")
            print("[UniversalPayslipProcessor]   Earnings: ₹\(earningsTotal) vs ₹\(anchors.grossPay) (\(String(format: "%.1f%%", earningsError * 100)))")
            print("[UniversalPayslipProcessor]   Deductions: ₹\(deductionsTotal) vs ₹\(anchors.totalDeductions) (\(String(format: "%.1f%%", deductionsError * 100)))")
        } else {
            print("[UniversalPayslipProcessor] ✅ Totals match anchors within 1%")
        }

        // Step 10: Extract date information from first page
        var month = ""
        var year = Calendar.current.component(.year, from: Date())

        if let dateInfo = dateExtractor.extractStatementDate(from: firstPageText) {
            month = dateInfo.month
            year = dateInfo.year
        } else {
            // Fallback to current month
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
        }

        // NEW: Step 11 - Use anchor values for credits and debits (ground truth)
        let credits = anchors.grossPay
        let debits = anchors.totalDeductions

        // Extract key tax and DSOP values
        let tax = deductions["Income Tax"] ?? deductions["ITAX"] ?? deductions.first(where: { $0.key.contains("ITAX") })?.value ?? 0.0
        let dsop = deductions["DSOP"] ?? deductions.first(where: { $0.key.contains("DSOP") })?.value ?? 0.0

        // Step 12: Extract personal information from first page
        let (name, accountNumber, panNumber) = dateExtractor.extractPersonalInfo(from: firstPageText)

        // Step 13: Create payslip item with anchor values
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name ?? "Defense Personnel",
            accountNumber: accountNumber ?? "",
            panNumber: panNumber ?? "",
            pdfData: nil
        )

        payslipItem.earnings = earnings
        payslipItem.deductions = deductions

        print("[UniversalPayslipProcessor] ✅ Payslip created - Credits: ₹\(credits), Debits: ₹\(debits)")
        print("[UniversalPayslipProcessor] Earnings components: \(earnings.count), Deductions: \(deductions.count)")

        // Record performance metrics
        let processingTime = Date().timeIntervalSince(startTime)
        ParserPerformanceMonitor.shared.recordMetrics(.init(
            processingTime: processingTime,
            componentsExtracted: earnings.count + deductions.count,
            credits: credits,
            debits: debits,
            parserType: "Universal",
            timestamp: Date()
        ))

        return payslipItem
    }

    /// Calculates confidence score for defense format detection
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Confidence score (0.0 to 1.0)
    func canProcess(text: String) -> Double {
        let score = calculateDefenseConfidence(for: text)
        print("[UniversalPayslipProcessor] Defense format confidence: \(String(format: "%.2f", score))")
        return score
    }

    // MARK: - Private Methods

    /// Calculates defense format confidence based on keywords
    private func calculateDefenseConfidence(for text: String) -> Double {
        let uppercaseText = text.uppercased()
        var score = 0.0

        let defenseKeywords: [String: Double] = [
            "ARMY": 0.4,
            "NAVY": 0.4,
            "AIR FORCE": 0.4,
            "INDIAN ARMY": 0.5,
            "INDIAN NAVY": 0.5,
            "INDIAN AIR FORCE": 0.5,
            "DEFENCE": 0.3,
            "MILITARY": 0.3,
            "PCDA": 0.4,
            "DSOP": 0.3,
            "AGIF": 0.2,
            "MSP": 0.2,
            "BASIC PAY": 0.2,
            "BPAY": 0.2
        ]

        for (keyword, weight) in defenseKeywords {
            if uppercaseText.contains(keyword) {
                score += weight
            }
        }

        return min(score, 1.0)
    }
}
