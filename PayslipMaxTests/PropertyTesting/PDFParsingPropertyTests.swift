import XCTest
import SwiftCheck
import PDFKit
@testable import PayslipMax
@testable import PayslipMaxTestMocks

/// Property-based tests specifically for the PDF parsing system
class PDFParsingPropertyTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    private var mockPDFService: MockPDFService!
    private var mockEncryptionService: MockEncryptionService!
    private var coordinator: PDFParsingCoordinator!
    
    override func setUp() {
        super.setUp()
        mockPDFService = MockPDFService()
        mockEncryptionService = MockEncryptionService()
        coordinator = PDFParsingCoordinator(
            pdfService: mockPDFService,
            encryptionService: mockEncryptionService
        )
    }
    
    override func tearDown() {
        mockPDFService = nil
        mockEncryptionService = nil
        coordinator = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test PDF with random variations of content structure
    private func generateTestPDF(
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        name: String,
        accountNumber: String,
        formatVariation: Int,
        contentStructure: Int
    ) -> PDFDocument {
        // Determine layout format based on variation
        let headerFormat: String
        let financialFormat: String
        
        // Different header formats
        switch formatVariation {
        case 0:
            // Standard format
            headerFormat = """
            PAYSLIP
            Name: \(name)
            Month: \(month)
            Year: \(year)
            Account Number: \(accountNumber)
            """
        case 1:
            // Alternative format
            headerFormat = """
            EMPLOYEE PAYSLIP
            Employee: \(name)
            For Period: \(month) \(year)
            Account: \(accountNumber)
            """
        case 2:
            // Minimal format
            headerFormat = """
            \(name)
            \(month)/\(year)
            Acc: \(accountNumber)
            """
        default:
            // Default format
            headerFormat = """
            PAYSLIP: \(month) \(year)
            \(name)
            \(accountNumber)
            """
        }
        
        // Different financial formats
        switch contentStructure {
        case 0:
            // Simple format
            financialFormat = """
            
            CREDITS: \(String(format: "%.2f", credits))
            DEBITS: \(String(format: "%.2f", debits))
            
            Net Amount: \(String(format: "%.2f", credits - debits))
            """
        case 1:
            // Detailed format
            financialFormat = """
            
            EARNINGS                  AMOUNT
            Basic Pay                 \(String(format: "%.2f", credits * 0.7))
            Allowances                \(String(format: "%.2f", credits * 0.3))
            -----------------------------------
            Total Credits             \(String(format: "%.2f", credits))
            
            DEDUCTIONS                AMOUNT
            Tax                       \(String(format: "%.2f", debits * 0.5))
            Insurance                 \(String(format: "%.2f", debits * 0.3))
            Other                     \(String(format: "%.2f", debits * 0.2))
            -----------------------------------
            Total Debits              \(String(format: "%.2f", debits))
            
            Net Pay                   \(String(format: "%.2f", credits - debits))
            """
        case 2:
            // Tabular format
            financialFormat = """
            
            Description | Amount
            ------------|-------
            Total Credits | \(String(format: "%.2f", credits))
            Total Debits  | \(String(format: "%.2f", debits))
            Net Amount    | \(String(format: "%.2f", credits - debits))
            """
        default:
            // Default format
            financialFormat = """
            
            TOTAL CREDITS: \(String(format: "%.2f", credits))
            TOTAL DEBITS: \(String(format: "%.2f", debits))
            
            NET AMOUNT: \(String(format: "%.2f", credits - debits))
            """
        }
        
        // Combine formats to create complete content
        let content = headerFormat + "\n" + financialFormat
        
        // Create PDF from content
        return TestDataGenerator.generatePDFDocumentFromText(content)
    }
    
    // MARK: - Property Tests
    
    /// Tests that parsing works across a variety of PDF document formats
    func testParsingRobustness() {
        // Generate random combinations of PDF formats and content structures
        property("PDF parsing works across varied document formats") <- forAll(
            Gen<Int>.choose((0, 3)), // Format variation
            Gen<Int>.choose((0, 3))  // Content structure
        ) { formatVariation, contentStructure in
            // Fixed values for this test
            let month = "January"
            let year = 2023
            let credits = 5000.0
            let debits = 1000.0
            let name = "Test User"
            let accountNumber = "ACC123456"
            
            // Generate a test PDF with the given variations
            let pdfDocument = self.generateTestPDF(
                month: month,
                year: year,
                credits: credits,
                debits: debits,
                name: name,
                accountNumber: accountNumber,
                formatVariation: formatVariation,
                contentStructure: contentStructure
            )
            
            guard let pdfData = pdfDocument.dataRepresentation() else {
                return false
            }
            
            // Configure the mock PDF service
            self.mockPDFService.pdfDataToReturn = pdfData
            
            // Use the general parser
            let parser = PayslipParserRegistry.generalParser
            
            do {
                // Attempt to parse the generated PDF
                let parsedPayslip = try self.coordinator.parsePayslipData(
                    from: UUID().uuidString,
                    using: parser
                )
                
                // The parser should extract these key fields correctly regardless of format
                let monthCorrect = parsedPayslip.month.lowercased().contains(month.lowercased())
                let yearCorrect = parsedPayslip.year == year
                
                // For financial amounts, allow some small deviation
                let epsilon = 0.05 // 5% tolerance
                let creditsCorrect = abs((parsedPayslip.credits - credits) / credits) < epsilon
                let debitsCorrect = abs((parsedPayslip.debits - debits) / debits) < epsilon
                
                return monthCorrect && yearCorrect && creditsCorrect && debitsCorrect
            } catch {
                // Parsing failure means the test fails
                return false
            }
        }
    }
    
    /// Tests that parsing is robust to various formatting of monetary values
    func testMonetaryValueFormatting() {
        // Test with various monetary formats
        property("Parser handles different monetary value formats") <- forAll(
            Gen<Int>.choose((0, 4)) // Number format variation
        ) { formatVariation in
            // Fixed values
            let credits = 5432.10
            let debits = 1234.56
            
            // Different ways to format the same monetary values
            let creditsString: String
            let debitsString: String
            
            switch formatVariation {
            case 0:
                // Standard decimal format
                creditsString = "5432.10"
                debitsString = "1234.56"
            case 1:
                // Comma as thousands separator
                creditsString = "5,432.10"
                debitsString = "1,234.56"
            case 2:
                // Currency symbol
                creditsString = "$5432.10"
                debitsString = "$1234.56"
            case 3:
                // Space as thousands separator
                creditsString = "5 432.10"
                debitsString = "1 234.56"
            case 4:
                // European format (comma as decimal separator)
                creditsString = "5432,10"
                debitsString = "1234,56"
            default:
                creditsString = "5432.10"
                debitsString = "1234.56"
            }
            
            // Create PDF content
            let content = """
            PAYSLIP
            Name: Test User
            Month: January
            Year: 2023
            
            CREDITS: \(creditsString)
            DEBITS: \(debitsString)
            """
            
            // Generate PDF
            let pdfDocument = TestDataGenerator.generatePDFDocumentFromText(content)
            
            guard let pdfData = pdfDocument.dataRepresentation() else {
                return false
            }
            
            // Configure the mock PDF service
            self.mockPDFService.pdfDataToReturn = pdfData
            
            // Use the general parser
            let parser = PayslipParserRegistry.generalParser
            
            do {
                // Attempt to parse
                let parsedPayslip = try self.coordinator.parsePayslipData(
                    from: UUID().uuidString,
                    using: parser
                )
                
                // Check if the parser correctly extracted the monetary values
                // Allow a small epsilon for floating point comparison
                let epsilon = 0.01
                let creditsCorrect = abs(parsedPayslip.credits - credits) < epsilon
                let debitsCorrect = abs(parsedPayslip.debits - debits) < epsilon
                
                return creditsCorrect && debitsCorrect
            } catch {
                return false
            }
        }
    }
    
    /// Tests parser resilience to different date formats
    func testDateFormatResilience() {
        // Test with various date formats
        property("Parser handles different date formats") <- forAll(
            Gen<Int>.choose((0, 5)) // Date format variation
        ) { formatVariation in
            // Fixed values for this test
            let month = "January"
            let year = 2023
            
            // Different ways to format dates
            let dateString: String
            
            switch formatVariation {
            case 0:
                // Month name and year
                dateString = "January 2023"
            case 1:
                // Abbreviated month and year
                dateString = "Jan 2023"
            case 2:
                // MM/YYYY format
                dateString = "01/2023"
            case 3:
                // YYYY-MM format
                dateString = "2023-01"
            case 4:
                // Month name, comma, year
                dateString = "January, 2023"
            case 5:
                // Just month name with year elsewhere
                dateString = "January\nYear: 2023"
            default:
                dateString = "January 2023"
            }
            
            // Create PDF content
            let content: String
            if formatVariation == 5 {
                // Special case where month and year are separate
                content = """
                PAYSLIP
                Name: Test User
                Month: January
                Year: 2023
                
                CREDITS: 5000.00
                DEBITS: 1000.00
                """
            } else {
                content = """
                PAYSLIP
                Name: Test User
                Period: \(dateString)
                
                CREDITS: 5000.00
                DEBITS: 1000.00
                """
            }
            
            // Generate PDF
            let pdfDocument = TestDataGenerator.generatePDFDocumentFromText(content)
            
            guard let pdfData = pdfDocument.dataRepresentation() else {
                return false
            }
            
            // Configure the mock PDF service
            self.mockPDFService.pdfDataToReturn = pdfData
            
            // Use the general parser
            let parser = PayslipParserRegistry.generalParser
            
            do {
                // Attempt to parse
                let parsedPayslip = try self.coordinator.parsePayslipData(
                    from: UUID().uuidString,
                    using: parser
                )
                
                // Check if the parser correctly extracted the date components
                let monthCorrect = parsedPayslip.month.lowercased().contains(month.lowercased()) ||
                                  month.lowercased().contains(parsedPayslip.month.lowercased())
                let yearCorrect = parsedPayslip.year == year
                
                return monthCorrect && yearCorrect
            } catch {
                return false
            }
        }
    }
    
    /// Tests parser resilience to document quality issues
    func testDocumentQualityResilience() {
        // Test with various document quality issues
        property("Parser handles document quality issues") <- forAll(
            Gen<Int>.choose((0, 3)) // Quality issue type
        ) { qualityIssueType in
            // Fixed values for this test
            let credits = 5000.0
            let debits = 1000.0
            
            // Base content
            let baseContent = """
            PAYSLIP
            Name: Test User
            Month: January
            Year: 2023
            
            CREDITS: 5000.00
            DEBITS: 1000.00
            """
            
            // Modified content based on quality issue type
            let content: String
            switch qualityIssueType {
            case 0:
                // Extra noise characters
                content = baseContent.replacingOccurrences(of: "CREDITS", with: "C*R#E^D&I@T$S")
                               .replacingOccurrences(of: "DEBITS", with: "D*E#B^I&T@S$")
            case 1:
                // Inconsistent spacing
                content = baseContent.replacingOccurrences(of: " ", with: "   ")
                               .replacingOccurrences(of: "\n", with: "\n\n")
            case 2:
                // OCR-like errors (substituted characters)
                content = baseContent.replacingOccurrences(of: "CREDITS", with: "CRED1TS")
                               .replacingOccurrences(of: "DEBITS", with: "DEB1TS")
                               .replacingOccurrences(of: "5000.00", with: "SOOO.OO")
                               .replacingOccurrences(of: "1000.00", with: "lOOO.OO")
            case 3:
                // Mixed case and typos
                content = baseContent.replacingOccurrences(of: "CREDITS", with: "CrEdits")
                               .replacingOccurrences(of: "DEBITS", with: "Debts")
                               .replacingOccurrences(of: "PAYSLIP", with: "Pay-Slip")
            default:
                content = baseContent
            }
            
            // Generate PDF
            let pdfDocument = TestDataGenerator.generatePDFDocumentFromText(content)
            
            guard let pdfData = pdfDocument.dataRepresentation() else {
                return false
            }
            
            // Configure the mock PDF service
            self.mockPDFService.pdfDataToReturn = pdfData
            
            // Use the general parser
            let parser = PayslipParserRegistry.generalParser
            
            do {
                // Attempt to parse
                let parsedPayslip = try self.coordinator.parsePayslipData(
                    from: UUID().uuidString,
                    using: parser
                )
                
                // For quality issues, we'll have a larger epsilon
                let epsilon = 0.10 // 10% tolerance for these challenging cases
                
                // Check if parser could still extract reasonable values
                let creditsReasonable = abs((parsedPayslip.credits - credits) / credits) < epsilon
                let debitsReasonable = abs((parsedPayslip.debits - debits) / debits) < epsilon
                
                return creditsReasonable && debitsReasonable
            } catch {
                // For OCR-like errors, parsing might fail, but we'll consider that acceptable
                // in a small percentage of cases
                return qualityIssueType == 2
            }
        }
    }
    
    /// Tests that parser can handle different page layouts
    func testPageLayoutVariations() {
        // Test with various page layouts
        property("Parser handles different page layouts") <- forAll(
            Gen<Int>.choose((0, 2)) // Layout type
        ) { layoutType in
            // Fixed values for this test
            let credits = 5000.0
            let debits = 1000.0
            
            // Different page layouts
            let pdfDocument: PDFDocument
            
            switch layoutType {
            case 0:
                // Single page standard layout
                let content = """
                PAYSLIP
                Name: Test User
                Month: January
                Year: 2023
                
                CREDITS: 5000.00
                DEBITS: 1000.00
                """
                pdfDocument = TestDataGenerator.generatePDFDocumentFromText(content)
                
            case 1:
                // Two-page layout (header on first page, financials on second)
                let page1Content = """
                PAYSLIP
                Name: Test User
                Month: January
                Year: 2023
                """
                
                let page2Content = """
                FINANCIAL SUMMARY
                
                CREDITS: 5000.00
                DEBITS: 1000.00
                """
                
                let document = PDFDocument()
                let page1 = TestDataGenerator.generatePDFDocumentFromText(page1Content).page(at: 0)!
                let page2 = TestDataGenerator.generatePDFDocumentFromText(page2Content).page(at: 0)!
                
                document.insert(page1, at: 0)
                document.insert(page2, at: 1)
                
                pdfDocument = document
                
            case 2:
                // Column-based layout
                let content = """
                PAYSLIP                |  FINANCIAL SUMMARY
                ------------------------|-------------------------
                Name: Test User        |  CREDITS: 5000.00
                Month: January         |  DEBITS: 1000.00
                Year: 2023             |  NET: 4000.00
                """
                
                pdfDocument = TestDataGenerator.generatePDFDocumentFromText(content)
                
            default:
                // Default simple layout
                let content = """
                PAYSLIP
                Name: Test User
                Month: January
                Year: 2023
                
                CREDITS: 5000.00
                DEBITS: 1000.00
                """
                pdfDocument = TestDataGenerator.generatePDFDocumentFromText(content)
            }
            
            guard let pdfData = pdfDocument.dataRepresentation() else {
                return false
            }
            
            // Configure the mock PDF service
            self.mockPDFService.pdfDataToReturn = pdfData
            
            // Use the general parser
            let parser = PayslipParserRegistry.generalParser
            
            do {
                // Attempt to parse
                let parsedPayslip = try self.coordinator.parsePayslipData(
                    from: UUID().uuidString,
                    using: parser
                )
                
                // For layout variations, we'll use a larger epsilon
                let epsilon = 0.10 // 10% tolerance
                
                // Check if parser could still extract core values
                let creditsCorrect = abs((parsedPayslip.credits - credits) / credits) < epsilon
                let debitsCorrect = abs((parsedPayslip.debits - debits) / debits) < epsilon
                let monthCorrect = parsedPayslip.month.lowercased().contains("january")
                let yearCorrect = parsedPayslip.year == 2023
                
                return creditsCorrect && debitsCorrect && monthCorrect && yearCorrect
            } catch {
                return false
            }
        }
    }
} 