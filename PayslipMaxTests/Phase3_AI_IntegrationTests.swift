import XCTest
@testable import PayslipMax

/// Integration tests for Phase 3 AI-powered financial validation system
final class Phase3_AI_IntegrationTests: XCTestCase {

    // MARK: - Properties

    private var financialIntelligenceService: FinancialIntelligenceService!
    private var militaryCodeRecognizer: MilitaryCodeRecognizer!
    private var pcdaValidator: PCDAFinancialValidator!
    private var smartTotalsReconciler: SmartTotalsReconciler!

    // Test data - Balanced PCDA format (Credits = Debits)
    private let testCredits = [
        "BASIC_PAY": 45000.0,
        "DA": 22500.0,
        "HRA": 13500.0,
        "MSP": 10000.0,
        "DSOPF": 5000.0
    ]

    private let testDebits = [
        "AGIF": 500.0,
        "INCOME_TAX": 7500.0,
        "PROFESSIONAL_TAX": 2500.0,
        "NET_AMOUNT": 85500.0  // Balance to make Credits = Debits in PCDA format
    ]

    private let testPrintedTotals = [
        "TOTAL_CREDITS": 95000.0,  // Slight discrepancy from actual (96000) for testing
        "TOTAL_DEBITS": 96000.0   // Should match total credits in PCDA
    ]

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize services
        financialIntelligenceService = FinancialIntelligenceService()
        militaryCodeRecognizer = MilitaryCodeRecognizer()
        pcdaValidator = PCDAFinancialValidator()
        smartTotalsReconciler = SmartTotalsReconciler()
    }

    override func tearDown() async throws {
        financialIntelligenceService = nil
        militaryCodeRecognizer = nil
        pcdaValidator = nil
        smartTotalsReconciler = nil

        try await super.tearDown()
    }

    // MARK: - Financial Intelligence Service Tests

    func testFinancialIntelligenceService_ValidatesFinancialData() async throws {
        // Given
        let extractedData = testCredits.merging(testDebits) { $1 }

        // When
        let result = try await financialIntelligenceService.validateFinancialData(
            extractedData: extractedData,
            printedTotals: testPrintedTotals,
            documentFormat: .pcda
        )

        // Then
        XCTAssertFalse(result.isValid, "Financial validation should fail due to discrepancies between extracted and printed totals")
        XCTAssertGreaterThan(result.confidence, 0.5, "Confidence should be reasonable")
        XCTAssertGreaterThan(result.issues.count, 0, "Should identify some validation issues")
    }

    func testFinancialIntelligenceService_DetectsOutliers() async throws {
        // Given - Create data with outliers
        let outlierCredits = testCredits.merging(["EXTREME_VALUE": 500000.0]) { $1 }

        // When
        let result = try await financialIntelligenceService.detectOutliers(
            amounts: outlierCredits,
            format: .pcda
        )

        // Then
        XCTAssertGreaterThan(result.outliers.count, 0, "Should detect outlier values")
        XCTAssertEqual(result.overallRisk, .extreme, "Extreme value should trigger extreme risk")
    }

    func testFinancialIntelligenceService_ReconcilesAmounts() async throws {
        // Given
        let expectedNet = 84500.0

        // When
        let result = try await financialIntelligenceService.reconcileAmounts(
            credits: testCredits,
            debits: testDebits,
            expectedNet: expectedNet
        )

        // Then
        XCTAssertGreaterThan(result.confidence, 0.5, "Reconciliation confidence should be reasonable")
        XCTAssertGreaterThanOrEqual(result.netAmount, 0, "Net amount should be non-negative")
    }

    // MARK: - Military Code Recognizer Tests

    func testMilitaryCodeRecognizer_RecognizesCodes() async throws {
        // Given
        let testElements = [
            LiteRTTextElement(text: "DSOPF", bounds: .zero, fontSize: 12.0, confidence: 0.9),
            LiteRTTextElement(text: "AGIF", bounds: .zero, fontSize: 12.0, confidence: 0.9),
            LiteRTTextElement(text: "MSP", bounds: .zero, fontSize: 12.0, confidence: 0.9)
        ]

        // When
        let result = try await militaryCodeRecognizer.recognizeCodes(in: testElements)

        // Then
        XCTAssertEqual(result.recognizedCodes.count, 3, "Should recognize all military codes")
        XCTAssertGreaterThan(result.confidence, 0.5, "Recognition confidence should be high")
    }

    func testMilitaryCodeRecognizer_ExpandsAbbreviations() async throws {
        // Given
        let code = "DSOPF"

        // When
        let expansion = try await militaryCodeRecognizer.expandAbbreviation(code)

        // Then
        XCTAssertNotNil(expansion, "Should expand DSOPF abbreviation")
        XCTAssertEqual(expansion?.fullName, "Defence Savings Option Plan Fund")
        XCTAssertTrue(expansion?.isMandatory == false, "DSOPF should not be mandatory")
    }

    func testMilitaryCodeRecognizer_ValidatesCodes() async throws {
        // Given
        let code = "DSOPF"
        let context = MilitaryCodeContext(
            rank: "Colonel",
            serviceType: "Army",
            location: "Delhi",
            payScale: "Level 14"
        )

        // When
        let validation = try await militaryCodeRecognizer.validateCode(code, context: context)

        // Then
        XCTAssertTrue(validation.isValid, "DSOPF should be valid for Colonel rank")
        XCTAssertGreaterThan(validation.confidence, 0.7, "Validation confidence should be high")
    }

    func testMilitaryCodeRecognizer_StandardizesCodes() async throws {
        // Given
        let codes = ["dsopf", "AGIF", "msp"]

        // When
        let standardized = try await militaryCodeRecognizer.standardizeCodes(codes)

        // Then
        XCTAssertEqual(standardized.count, 3, "Should standardize all codes")
        XCTAssertTrue(standardized.allSatisfy { $0.confidence > 0.8 }, "All standardizations should be confident")
    }

    // MARK: - PCDA Financial Validator Tests

    func testPCDAFinancialValidator_BasicValidation() throws {
        // Given
        let credits = testCredits
        let debits = testDebits

        // When
        let result = pcdaValidator.validatePCDAExtraction(
            credits: credits,
            debits: debits,
            remittance: 84500.0
        )

        // Then
        XCTAssertTrue(result.isValid, "Basic PCDA validation should pass")
    }

    func testPCDAFinancialValidator_AIValidation() async throws {
        // Given
        let extractedData = testCredits.merging(testDebits) { $1 }

        // When
        let result = try await pcdaValidator.validateWithAI(
            extractedData: extractedData,
            printedTotals: testPrintedTotals,
            documentFormat: .pcda
        )

        // Then
        XCTAssertFalse(result.isValid, "AI-powered validation should fail due to discrepancies")
        if case .enhanced(let enhancedResult) = result {
            XCTAssertGreaterThan(enhancedResult.confidence, 0.5, "AI confidence should be reasonable")
            XCTAssertNotNil(enhancedResult.primaryIssue, "Should identify validation issues")
        }
    }

    // MARK: - Smart Totals Reconciler Tests

    func testSmartTotalsReconciler_ReconcilesTotals() async throws {
        // Given
        let expectedCredits = 95000.0
        let expectedDebits = 10500.0

        // When
        let result = try await smartTotalsReconciler.reconcileTotals(
            extractedCredits: testCredits,
            extractedDebits: testDebits,
            expectedCredits: expectedCredits,
            expectedDebits: expectedDebits,
            documentFormat: .pcda
        )

        // Then
        XCTAssertGreaterThan(result.confidence, 0.5, "Reconciliation confidence should be reasonable")
        XCTAssertGreaterThan(result.appliedCorrections.count, 0, "Should apply some corrections")
    }

    func testSmartTotalsReconciler_SuggestsCorrections() async throws {
        // Given
        let discrepancies = [
            ReconciliationDiscrepancy(
                component: "TOTAL_CREDITS",
                extractedValue: 95000.0,
                expectedValue: 94500.0,
                discrepancyType: .amountMismatch,
                severity: .medium,
                explanation: "Total credits mismatch"
            )
        ]

        let context = ReconciliationContext(
            documentFormat: .pcda,
            hasPrintedTotals: true,
            componentCount: 8,
            totalAmount: 95000.0
        )

        // When
        let suggestions = try await smartTotalsReconciler.suggestCorrections(
            discrepancies: discrepancies,
            context: context
        )

        // Then
        XCTAssertGreaterThan(suggestions.count, 0, "Should generate correction suggestions")
    }

    func testSmartTotalsReconciler_AppliesCorrections() async throws {
        // Given
        let corrections = [
            ReconciliationCorrection(
                component: "BASIC_PAY",
                originalValue: 45000.0,
                correctedValue: 45000.0,
                reason: "Rounding applied",
                confidence: 0.8
            )
        ]

        // When
        let correctedTotals = try await smartTotalsReconciler.applyCorrections(
            credits: testCredits,
            debits: testDebits,
            corrections: corrections
        )

        // Then
        XCTAssertGreaterThan(correctedTotals.confidence, 0.5, "Applied corrections should maintain confidence")
        XCTAssertGreaterThanOrEqual(correctedTotals.netAmount, 0, "Net amount should remain non-negative")
    }

    func testSmartTotalsReconciler_ValidatesReconciliation() async throws {
        // Given
        let originalTotals = OriginalTotals(
            credits: testCredits,
            debits: testDebits,
            netAmount: 0.0  // Balanced PCDA: Credits (96000) - Debits (96000) = 0
        )

        let reconciledTotals = CorrectedTotals(
            credits: testCredits,
            debits: testDebits,
            netAmount: 0.0,  // Consistent with original
            confidence: 0.9
        )

        // When
        let validation = try await smartTotalsReconciler.validateReconciliation(
            originalTotals: originalTotals,
            reconciledTotals: reconciledTotals
        )

        // Then
        XCTAssertTrue(validation.isValid, "Reconciliation validation should pass for consistent data")
        XCTAssertGreaterThan(validation.qualityScore, 0.5, "Quality score should be reasonable")
    }

    // MARK: - End-to-End Integration Tests

    func testEndToEnd_FinancialValidationPipeline() async throws {
        // Given - Complete payslip data
        let extractedData = testCredits.merging(testDebits) { $1 }

        // When - Run complete AI validation pipeline
        let _ = try await financialIntelligenceService.validateFinancialData(
            extractedData: extractedData,
            printedTotals: testPrintedTotals,
            documentFormat: .pcda
        )

        let pcdaValidation = try await pcdaValidator.validateWithAI(
            extractedData: extractedData,
            printedTotals: testPrintedTotals,
            documentFormat: .pcda
        )

        let reconciliation = try await smartTotalsReconciler.reconcileTotals(
            extractedCredits: testCredits,
            extractedDebits: testDebits,
            expectedCredits: testPrintedTotals["TOTAL_CREDITS"],
            expectedDebits: testPrintedTotals["TOTAL_DEBITS"],
            documentFormat: .pcda
        )

        // Then - All components should work together
        // Note: Enhanced AI validation detects discrepancies and fails, which is correct behavior
        XCTAssertFalse(pcdaValidation.isValid, "Enhanced PCDA validation should fail due to AI-detected discrepancies")
        XCTAssertGreaterThan(reconciliation.confidence, 0.4, "Reconciliation should be reasonably confident")
        XCTAssertGreaterThan(reconciliation.appliedCorrections.count, 0, "Should apply some corrections")

        // Validate reconciliation results
        let originalTotals = OriginalTotals(
            credits: testCredits,
            debits: testDebits,
            netAmount: 0.0  // Balanced PCDA format
        )

        let validation = try await smartTotalsReconciler.validateReconciliation(
            originalTotals: originalTotals,
            reconciledTotals: CorrectedTotals(
                credits: reconciliation.reconciledCredits,
                debits: reconciliation.reconciledDebits,
                netAmount: reconciliation.netAmount,
                confidence: reconciliation.confidence
            )
        )

        XCTAssertTrue(validation.isValid, "End-to-end validation should pass")
    }

    func testEndToEnd_MilitaryCodeProcessing() async throws {
        // Given - Military payslip text elements
        let militaryElements = [
            LiteRTTextElement(text: "DSOPF", bounds: .zero, fontSize: 12.0, confidence: 0.9),
            LiteRTTextElement(text: "AGIF", bounds: .zero, fontSize: 12.0, confidence: 0.9),
            LiteRTTextElement(text: "MSP", bounds: .zero, fontSize: 12.0, confidence: 0.9),
            LiteRTTextElement(text: "HRA", bounds: .zero, fontSize: 12.0, confidence: 0.9)
        ]

        // When - Process military codes
        let recognition = try await militaryCodeRecognizer.recognizeCodes(in: militaryElements)

        // Then - Should recognize and process codes correctly
        XCTAssertEqual(recognition.recognizedCodes.count, 4, "Should recognize all military codes")

        // Test expansion for each recognized code
        for code in recognition.recognizedCodes {
            let expansion = try await militaryCodeRecognizer.expandAbbreviation(code.standardizedCode)
            XCTAssertNotNil(expansion, "Should expand \(code.standardizedCode)")
            XCTAssertFalse(expansion!.fullName.isEmpty, "Expansion should have full name")
        }

        // Test standardization
        let originalCodes = ["dsopf", "agif", "msp", "hra"]
        let standardized = try await militaryCodeRecognizer.standardizeCodes(originalCodes)
        XCTAssertEqual(standardized.count, 4, "Should standardize all codes")
        XCTAssertTrue(standardized.allSatisfy { $0.confidence > 0.8 }, "Standardization should be confident")
    }

    // MARK: - Performance Tests

    func testPerformance_FinancialIntelligenceValidation() async throws {
        // Given
        let extractedData = testCredits.merging(testDebits) { $1 }

        // When - Measure performance
        let startTime = Date()
        let result = try await financialIntelligenceService.validateFinancialData(
            extractedData: extractedData,
            printedTotals: testPrintedTotals,
            documentFormat: .pcda
        )
        let endTime = Date()

        // Then - Should complete within reasonable time
        let executionTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(executionTime, 2.0, "Financial validation should complete within 2 seconds")
        XCTAssertFalse(result.isValid, "AI validation should fail due to discrepancies (consistent with other AI validation tests)")
        XCTAssertGreaterThan(result.confidence, 0.0, "Should have some confidence in result")
        XCTAssertGreaterThan(result.issues.count, 0, "Should identify validation issues")
    }

    func testPerformance_MilitaryCodeRecognition() async throws {
        // Given
        let testElements = (1...50).map { index in
            LiteRTTextElement(text: "DSOPF", bounds: .zero, fontSize: 12.0, confidence: 0.9)
        }

        // When - Measure performance
        let startTime = Date()
        let result = try await militaryCodeRecognizer.recognizeCodes(in: testElements)
        let endTime = Date()

        // Then - Should complete within reasonable time
        let executionTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(executionTime, 1.0, "Military code recognition should complete within 1 second")
        XCTAssertEqual(result.recognizedCodes.count, 50, "Should recognize all codes")
    }
}
