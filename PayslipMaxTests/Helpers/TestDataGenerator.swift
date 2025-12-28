import Foundation
import PDFKit
@testable import PayslipMax

/// Refactored TestDataGenerator that uses extracted components
/// This class now serves as a facade for the modular test data generation system
class TestDataGenerator {

    // MARK: - Dependencies

    private let defenseDataFactory: DefensePayslipDataFactoryProtocol
    private let defensePDFGenerator: DefensePayslipPDFGeneratorProtocol
    private let defenseValidator: DefenseTestValidatorProtocol
    private let scenarioBuilder: ScenarioBuilderProtocol

    // MARK: - Initialization

    init(
        defenseDataFactory: DefensePayslipDataFactoryProtocol = DefensePayslipDataFactory(),
        defensePDFGenerator: DefensePayslipPDFGeneratorProtocol = DefensePayslipPDFGenerator(),
        defenseValidator: DefenseTestValidatorProtocol = DefenseTestValidator(),
        scenarioBuilder: ScenarioBuilderProtocol = ScenarioBuilder()
    ) {
        self.defenseDataFactory = defenseDataFactory
        self.defensePDFGenerator = defensePDFGenerator
        self.defenseValidator = defenseValidator
        self.scenarioBuilder = scenarioBuilder
    }

    // MARK: - PayslipItem Generation (Delegated to DataFactory)

    /// Creates a standard sample defense payslip item for testing using parameter struct
    static func samplePayslipItem(params: DefensePayslipDataParams = .default) -> PayslipItem {
        let factory = DefensePayslipDataFactory()
        return factory.createDefensePayslipItem(params: params)
    }

    /// Creates a collection of sample defense payslips spanning multiple months
    static func samplePayslipItems(count: Int = 12, serviceBranch: DefenseServiceBranch = .army) -> [PayslipItem] {
        let factory = DefensePayslipDataFactory()
        return factory.createDefensePayslipItems(count: count, serviceBranch: serviceBranch)
    }

    /// Creates a defense payslip item that represents an edge case
    static func edgeCasePayslipItem(type: DefenseEdgeCaseType) -> PayslipItem {
        let factory = DefensePayslipDataFactory()
        return factory.createEdgeCaseDefensePayslip(type: type)
    }

    // MARK: - PDF Generation (Delegated to PDFGenerator)

    /// Creates a sample PDF document with text for testing
    static func samplePDFDocument(withText text: String = "Sample PDF for testing") -> PDFDocument {
        let generator = PDFGenerator()
        return generator.createSamplePDFDocument(withText: text)
    }

    /// Creates a sample defense payslip PDF for testing using parameter struct
    static func samplePayslipPDF(params: DefensePayslipPDFParams = .default) -> PDFDocument {
        let generator = DefensePayslipPDFGenerator()
        return generator.createDefensePayslipPDF(params: params)
    }

    // MARK: - Additional PDF Generation Methods (Delegated to PDFGenerator)

    /// Creates a PDF with image content for testing
    static func createPDFWithImage() -> Data {
        let generator = PDFGenerator()
        return generator.createPDFWithImage()
    }

    /// Creates a multi-page PDF for testing large documents
    static func createMultiPagePDF(pageCount: Int) -> Data {
        let generator = PDFGenerator()
        return generator.createMultiPagePDF(pageCount: pageCount)
    }

    /// Creates a PDF with table content for testing
    static func createPDFWithTable() -> Data {
        let generator = PDFGenerator()
        return generator.createPDFWithTable()
    }

    // MARK: - Scenario Building (Delegated to ScenarioBuilder)

    /// Builds a complete monthly payslip scenario for testing
    static func buildMonthlyScenario(for month: String, year: Int, baseAmount: Double) -> TestScenario {
        let builder = ScenarioBuilder()
        return builder.buildMonthlyScenario(for: month, year: year, baseAmount: baseAmount)
    }

    /// Builds a yearly scenario with all 12 months
    static func buildYearlyScenario(startingYear: Int, baseAmount: Double) -> TestScenario {
        let builder = ScenarioBuilder()
        return builder.buildYearlyScenario(startingYear: startingYear, baseAmount: baseAmount)
    }

    /// Builds an edge case scenario for boundary testing
    static func buildEdgeCaseScenario(type: ScenarioType) -> TestScenario {
        let builder = ScenarioBuilder()
        return builder.buildEdgeCaseScenario(type: type)
    }

    /// Builds a mixed scenario with various pay patterns
    static func buildMixedScenario() -> TestScenario {
        let builder = ScenarioBuilder()
        return builder.buildMixedScenario()
    }

    // MARK: - Validation (Delegated to TestDataValidator)

    /// Validates a single defense payslip item for data integrity
    static func validatePayslipItem(_ payslip: PayslipItem) throws -> ValidationResult {
        let validator = DefenseTestValidator()
        return try validator.validateDefensePayslipItem(payslip)
    }

    /// Validates an array of defense payslip items
    static func validatePayslipItems(_ payslips: [PayslipItem]) throws -> ValidationResult {
        let validator = DefenseTestValidator()
        return try validator.validateDefensePayslipItems(payslips)
    }

    /// Validates a TestScenario for completeness
    static func validateTestScenario(_ scenario: TestScenario) throws -> ValidationResult {
        let validator = TestDataValidator(
            payslipValidator: PayslipValidationService(),
            pdfValidator: PDFValidationService()
        )
        return try validator.validateTestScenario(scenario)
    }

    /// Validates PDF data for basic integrity
    static func validatePDFData(_ data: Data) -> ValidationResult {
        let validator = TestDataValidator(
            payslipValidator: PayslipValidationService(),
            pdfValidator: PDFValidationService()
        )
        return validator.validatePDFData(data)
    }

    /// Validates that calculated totals match expected values
    static func validateTotals(payslips: [PayslipItem], expectedCredits: Double, expectedDebits: Double) -> ValidationResult {
        let validator = TestDataValidator(
            payslipValidator: PayslipValidationService(),
            pdfValidator: PDFValidationService()
        )
        return validator.validateTotals(payslips: payslips, expectedCredits: expectedCredits, expectedDebits: expectedDebits)
    }

    // MARK: - Convenience Methods

    /// Creates a validated payslip item with automatic validation using parameter struct
    static func createValidatedPayslipItem(params: DefensePayslipDataParams = .default) throws -> PayslipItem {
        let payslip = samplePayslipItem(params: params)

        let validationResult = try validatePayslipItem(payslip)
        if !validationResult.isValid {
            throw TestDataError.validationFailed(errors: validationResult.errors)
        }

        return payslip
    }

    /// Creates a complete test scenario with validation
    static func createValidatedScenario(for month: String, year: Int, baseAmount: Double) throws -> TestScenario {
        let scenario = buildMonthlyScenario(for: month, year: year, baseAmount: baseAmount)
        let validationResult = try validateTestScenario(scenario)

        if !validationResult.isValid {
            throw TestDataError.validationFailed(errors: validationResult.errors)
        }

        return scenario
    }
}

// MARK: - Supporting Types
// Note: EdgeCaseType is defined in DataFactory.swift

/// Errors that can occur during test data generation
enum TestDataError: Error {
    case validationFailed(errors: [ValidationError])
    case invalidConfiguration(description: String)
    case dataGenerationFailed(description: String)
}
