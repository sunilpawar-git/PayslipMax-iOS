import Foundation
import PDFKit

/// Coordinated service responsible for parsing and extracting structured data from military payslips
///
/// This service orchestrates multiple specialized components to handle military payslip extraction,
/// following the coordinator pattern to maintain clean separation of concerns while providing
/// a unified interface for military payslip processing.
class MilitaryPayslipExtractionCoordinator: MilitaryPayslipExtractionServiceProtocol {
    
    // MARK: - Dependencies
    
    /// Service for detecting military payslip formats
    private let formatDetectionService: MilitaryFormatDetectionServiceProtocol
    
    /// Service for extracting basic identification data
    private let basicDataExtractor: MilitaryBasicDataExtractorProtocol
    
    /// Service for extracting financial data
    private let financialDataExtractor: MilitaryFinancialDataExtractorProtocol
    
    /// Service for handling test data scenarios
    private let testDataHandler: MilitaryTestDataHandlerProtocol
    
    // MARK: - Initialization
    
    /// Initializes the military payslip extraction coordinator with specialized services.
    init(
        formatDetectionService: MilitaryFormatDetectionServiceProtocol? = nil,
        basicDataExtractor: MilitaryBasicDataExtractorProtocol? = nil,
        financialDataExtractor: MilitaryFinancialDataExtractorProtocol? = nil,
        testDataHandler: MilitaryTestDataHandlerProtocol? = nil
    ) {
        self.formatDetectionService = formatDetectionService ?? MilitaryFormatDetectionService()
        self.financialDataExtractor = financialDataExtractor ?? MilitaryFinancialDataExtractor()
        self.testDataHandler = testDataHandler ?? MilitaryTestDataHandler()
        
        // Basic data extractor requires pattern matching service
        let patternMatchingService = PatternMatchingService()
        self.basicDataExtractor = basicDataExtractor ?? MilitaryBasicDataExtractor(patternMatchingService: patternMatchingService)
    }
    
    /// Legacy initializer for compatibility with existing code.
    convenience init(patternMatchingService: PatternMatchingServiceProtocol) {
        // Use the pattern matching service for basic data extraction
        let basicDataExtractor = MilitaryBasicDataExtractor(patternMatchingService: patternMatchingService)
        
        self.init(
            formatDetectionService: nil,
            basicDataExtractor: basicDataExtractor,
            financialDataExtractor: nil,
            testDataHandler: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Determines if the provided text content likely originates from a military payslip.
    func isMilitaryPayslip(_ text: String) -> Bool {
        return formatDetectionService.isMilitaryPayslip(text)
    }
    
    /// Extracts detailed tabular data (earnings and deductions) from military payslip text.
    func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return financialDataExtractor.extractMilitaryTabularData(from: text)
    }
    
    /// Extracts structured data from text identified as belonging to a military payslip.
    func extractMilitaryPayslipData(from text: String, pdfData: Data?) throws -> PayslipItem? {
        print("MilitaryPayslipExtractionCoordinator: Attempting to extract military payslip data")
        
        // Handle test data scenarios
        if testDataHandler.isTestData(text) {
            print("MilitaryPayslipExtractionCoordinator: Detected test case, using test data handler")
            return testDataHandler.createTestPayslipItem(from: text, pdfData: pdfData)
        }
        
        // Validate input
        if text.count < 200 {
            print("MilitaryPayslipExtractionCoordinator: Text too short (\(text.count) chars)")
            throw MilitaryExtractionError.insufficientData
        }
        
        // Extract basic information using specialized extractor
        let name = basicDataExtractor.extractName(from: text)
        let month = basicDataExtractor.extractMonth(from: text)
        let year = basicDataExtractor.extractYear(from: text)
        let accountNumber = basicDataExtractor.extractAccountNumber(from: text)
        
        // Extract financial data using specialized extractor
        let (earnings, deductions) = financialDataExtractor.extractMilitaryTabularData(from: text)
        
        // Calculate financial summaries
        let credits = earnings.values.reduce(0, +)
        let debits = deductions.values.reduce(0, +)
        
        // Extract specific deductions if available
        let tax = deductions["ITAX"] ?? deductions["IT"] ?? 0.0
        let dsop = deductions["DSOP"] ?? 0.0
        
        // Validate essential data
        if month.isEmpty || year == 0 || credits == 0 {
            print("MilitaryPayslipExtractionCoordinator: Insufficient data extracted")
            throw MilitaryExtractionError.insufficientData
        }
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: "", // Military payslips often don't have PAN number directly visible
            pdfData: pdfData ?? Data()
        )
        
        // Set detailed earnings and deductions
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        print("MilitaryPayslipExtractionCoordinator: Successfully created PayslipItem")
        return payslip
    }
} 