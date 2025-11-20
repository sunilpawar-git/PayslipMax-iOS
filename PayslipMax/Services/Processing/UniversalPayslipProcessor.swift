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

    /// Processes payslip using universal search engine
    /// NOTE: Currently synchronous to match protocol. Will be async in Phase 5.
    /// - Parameter text: The full text extracted from the PDF
    /// - Returns: A PayslipItem with extracted data
    /// - Throws: PayslipError if essential data cannot be extracted
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[UniversalPayslipProcessor] Processing with universal search engine")

        guard text.count >= 100 else {
            throw PayslipError.invalidData
        }

        // Use blocking Task for now (will be native async in Phase 5)
        var searchResults: [String: PayCodeSearchResult] = [:]
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            searchResults = await universalSearchEngine.searchAllPayCodes(in: text)
            semaphore.signal()
        }

        semaphore.wait()

        print("[UniversalPayslipProcessor] Found \(searchResults.count) components via universal search")

        // Step 2: Classify into earnings/deductions
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        for (code, result) in searchResults {
            // Use the section from search result if available
            switch result.section {
            case .earnings:
                earnings[code] = result.value
                print("[UniversalPayslipProcessor] \(code) = ₹\(result.value) → EARNINGS (search result)")
            case .deductions:
                deductions[code] = result.value
                print("[UniversalPayslipProcessor] \(code) = ₹\(result.value) → DEDUCTIONS (search result)")
            case .unknown:
                // Fall back to classification engine for unknown sections
                let classification = classificationEngine.classifyComponent(code)
                switch classification {
                case .guaranteedEarnings, .universalDualSection:
                    earnings[code] = result.value
                    print("[UniversalPayslipProcessor] \(code) = ₹\(result.value) → EARNINGS (classification)")
                case .guaranteedDeductions:
                    deductions[code] = result.value
                    print("[UniversalPayslipProcessor] \(code) = ₹\(result.value) → DEDUCTIONS (classification)")
                }
            }
        }

        // Step 3: Extract date information
        var month = ""
        var year = Calendar.current.component(.year, from: Date())

        if let dateInfo = dateExtractor.extractStatementDate(from: text) {
            month = dateInfo.month
            year = dateInfo.year
        } else {
            // Fallback to current month
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
        }

        // Step 4: Validate and get totals
        let (credits, debits) = validationCoordinator.validateAndGetTotals(
            earnings: earnings,
            deductions: deductions,
            legacyData: [:]  // No legacy data in universal system
        )

        // Extract key tax and DSOP values
        let tax = deductions["Income Tax"] ?? deductions["ITAX"] ?? 0.0
        let dsop = deductions["DSOP"] ?? 0.0

        // Step 5: Extract personal information
        let (name, accountNumber, panNumber) = dateExtractor.extractPersonalInfo(from: text)

        // Step 6: Create payslip item
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
