import Foundation
import PDFKit
@testable import PayslipMax

/// Refactored TestDataGenerator that uses extracted components
/// This class now serves as a facade for the modular test data generation system
class TestDataGenerator {
    
    // MARK: - Dependencies

    private let dataFactory: DataFactoryProtocol
    private let pdfGenerator: PDFGeneratorProtocol
    private let scenarioBuilder: ScenarioBuilderProtocol
    private let validator: TestDataValidatorProtocol

    // MARK: - Initialization

    init(
        dataFactory: DataFactoryProtocol = DataFactory(),
        pdfGenerator: PDFGeneratorProtocol = PDFGenerator(),
        scenarioBuilder: ScenarioBuilderProtocol = ScenarioBuilder(),
        validator: TestDataValidatorProtocol = TestDataValidator()
    ) {
        self.dataFactory = dataFactory
        self.pdfGenerator = pdfGenerator
        self.scenarioBuilder = scenarioBuilder
        self.validator = validator
    }

    // MARK: - PayslipItem Generation (Delegated to DataFactory)
    
    /// Creates a standard sample PayslipItem for testing
    static func samplePayslipItem(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0,
        name: String = "John Doe",
        accountNumber: String = "XXXX1234",
        panNumber: String = "ABCDE1234F"
    ) -> PayslipItem {
        let factory = DataFactory()
        return factory.createPayslipItem(
            id: id, month: month, year: year, credits: credits, debits: debits,
            dsop: dsop, tax: tax, name: name, accountNumber: accountNumber, panNumber: panNumber
        )
    }
    
    /// Creates a collection of sample payslips spanning multiple months
    static func samplePayslipItems(count: Int = 12) -> [PayslipItem] {
        let factory = DataFactory()
        return factory.createPayslipItems(count: count)
    }
    
    /// Creates a PayslipItem that represents an edge case
    static func edgeCasePayslipItem(type: EdgeCaseType) -> PayslipItem {
        let factory = DataFactory()
        return factory.createEdgeCasePayslipItem(type: type)
    }

    // MARK: - PDF Generation (Delegated to PDFGenerator)
    
    /// Creates a sample PDF document with text for testing
    static func samplePDFDocument(withText text: String = "Sample PDF for testing") -> PDFDocument {
        let generator = PDFGenerator()
        return generator.createSamplePDFDocument(withText: text)
    }
    
    /// Creates a sample payslip PDF for testing
    static func samplePayslipPDF(
        name: String = "John Doe",
        rank: String = "Captain",
        id: String = "ID123456",
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0
    ) -> PDFDocument {
        let generator = PDFGenerator()
        return generator.createSamplePayslipPDF(
            name: name, rank: rank, id: id, month: month, year: year,
            credits: credits, debits: debits, dsop: dsop, tax: tax
        )
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

    /// Validates a single PayslipItem for data integrity
    static func validatePayslipItem(_ payslip: PayslipItem) throws -> ValidationResult {
        let validator = TestDataValidator()
        return try validator.validatePayslipItem(payslip)
    }

    /// Validates an array of PayslipItems
    static func validatePayslipItems(_ payslips: [PayslipItem]) throws -> ValidationResult {
        let validator = TestDataValidator()
        return try validator.validatePayslipItems(payslips)
    }

    /// Validates a TestScenario for completeness
    static func validateTestScenario(_ scenario: TestScenario) throws -> ValidationResult {
        let validator = TestDataValidator()
        return try validator.validateTestScenario(scenario)
    }

    /// Validates PDF data for basic integrity
    static func validatePDFData(_ data: Data) -> ValidationResult {
        let validator = TestDataValidator()
        return validator.validatePDFData(data)
    }

    /// Validates that calculated totals match expected values
    static func validateTotals(payslips: [PayslipItem], expectedCredits: Double, expectedDebits: Double) -> ValidationResult {
        let validator = TestDataValidator()
        return validator.validateTotals(payslips: payslips, expectedCredits: expectedCredits, expectedDebits: expectedDebits)
    }

    // MARK: - Convenience Methods

    /// Creates a validated payslip item with automatic validation
    static func createValidatedPayslipItem(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0,
        name: String = "John Doe",
        accountNumber: String = "XXXX1234",
        panNumber: String = "ABCDE1234F"
    ) throws -> PayslipItem {
        let payslip = samplePayslipItem(
            id: id, month: month, year: year, credits: credits, debits: debits,
            dsop: dsop, tax: tax, name: name, accountNumber: accountNumber, panNumber: panNumber
        )

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

/// Edge case types for backward compatibility
enum EdgeCaseType {
    case zeroValues
    case negativeBalance
    case veryLargeValues
    case decimalPrecision
    case specialCharacters
}

/// Errors that can occur during test data generation
enum TestDataError: Error {
    case validationFailed(errors: [ValidationError])
    case invalidConfiguration(description: String)
    case dataGenerationFailed(description: String)
}
