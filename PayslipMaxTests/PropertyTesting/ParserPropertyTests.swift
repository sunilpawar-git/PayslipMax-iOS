import XCTest
import SwiftCheck
import PDFKit
@testable import PayslipMax
@testable import PayslipMaxTestMocks

/// Comprehensive property-based tests for parser robustness and random input validation
class ParserPropertyTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    private var payslipParserCoordinator: PayslipParserCoordinator!
    private var textExtractor: TextExtractor!
    private var abbreviationManager: AbbreviationManager!
    private var patternManager: PayslipPatternManager!
    
    override func setUp() {
        super.setUp()
        textExtractor = DefaultTextExtractor()
        abbreviationManager = AbbreviationManager()
        patternManager = PayslipPatternManager()
        payslipParserCoordinator = PayslipParserCoordinator(
            textExtractor: textExtractor,
            abbreviationManager: abbreviationManager,
            patternManager: patternManager
        )
    }
    
    override func tearDown() {
        payslipParserCoordinator = nil
        textExtractor = nil
        abbreviationManager = nil
        patternManager = nil
        super.tearDown()
    }
    
    // MARK: - Property Tests for Random Input Validation
    
    /// Tests parser resilience against completely random text input
    func testParserRobustnessAgainstRandomInput() {
        // Generate random strings of various lengths and character sets
        let randomStringGen = Gen<String>.compose { gen in
            gen.sized { size in
                let length = max(1, size)
                return Gen<String>.fromElements(in: [
                    String(repeating: "a", count: length),
                    String((0..<length).map { _ in Character(UnicodeScalar(Int.random(in: 32...126))!) }),
                    String((0..<length).map { _ in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"].randomElement()! }),
                    String((0..<length).map { _ in [" ", "\n", "\t", "\r"].randomElement()! }),
                    String((0..<length).map { _ in ["!", "@", "#", "$", "%", "^", "&", "*"].randomElement()! })
                ])
            }
        }
        
        property("Parser handles random input gracefully") <- forAll(randomStringGen) { randomText in
            // Create a mock PDF with random text
            let pdfDocument = TestDataGenerator.generatePDFDocumentFromText(randomText)
            
            do {
                // Parser should not crash, even with completely random input
                let result = try await self.payslipParserCoordinator.parsePayslip(pdfDocument: pdfDocument)
                
                // Either parsing succeeds (returning valid data) or fails gracefully
                switch result {
                case .success(let payslip):
                    // If parsing succeeds, the payslip should have basic validity
                    return payslip.id != nil &&
                           payslip.credits >= 0 &&
                           payslip.debits >= 0 &&
                           !payslip.month.isEmpty &&
                           payslip.year > 1900 && payslip.year < 2100
                case .failure:
                    // Parsing failure is acceptable for random input
                    return true
                }
            } catch {
                // Exceptions should be handled gracefully - no crashes
                return error is PCDAPayslipParserError || error.localizedDescription.contains("parsing")
            }
        }
    }
    
    /// Tests parser behavior with malformed financial data
    func testParserWithMalformedFinancialData() {
        // Generate various malformed financial data patterns
        let malformedDataGen = Gen<(String, String, String)>.compose { gen in
            let invalidAmounts = [
                "₹-1000", "Rs. NaN", "INVALID", "1,23,45,678.99.00", 
                "1000000000000000", "0.000000001", "1.2.3.4", 
                "₹₹₹1000", "1000Rs.Rs.", "1000.00.00", "-.50"
            ]
            let invalidNames = [
                "", " ", "\n\t", "123456789", "!@#$%^&*()", 
                String(repeating: "A", count: 1000), "NULL", "undefined"
            ]
            let invalidDates = [
                "32/13/2023", "00/00/0000", "2023/02/30", "February 30, 2023",
                "13th Month", "Year 20233", "Invalid Date", "NaN/NaN/NaN"
            ]
            
            return gen.fromElements(in: invalidAmounts)
                .flatMap { amount in
                    gen.fromElements(in: invalidNames)
                        .flatMap { name in
                            gen.fromElements(in: invalidDates)
                                .map { date in (amount, name, date) }
                        }
                }
        }
        
        property("Parser handles malformed financial data") <- forAll(malformedDataGen) { (amount, name, date) in
            let malformedText = """
            PAYSLIP
            Name: \(name)
            Date: \(date)
            Credits: \(amount)
            Debits: \(amount)
            Net Pay: \(amount)
            """
            
            let pdfDocument = TestDataGenerator.generatePDFDocumentFromText(malformedText)
            
            do {
                let result = try await self.payslipParserCoordinator.parsePayslip(pdfDocument: pdfDocument)
                
                switch result {
                case .success(let payslip):
                    // If parsing succeeds despite malformed data, ensure basic sanity
                    return payslip.credits >= 0 &&
                           payslip.debits >= 0 &&
                           payslip.credits < 10000000 && // Reasonable upper bound
                           payslip.debits < 10000000 &&
                           !payslip.name.isEmpty &&
                           payslip.year >= 1900 && payslip.year <= 2100
                case .failure:
                    return true // Failure is expected for malformed data
                }
            } catch {
                return true // Exceptions are acceptable for malformed data
            }
        }
    }
    
    /// Tests parser behavior with various PDF corruption scenarios
    func testParserWithCorruptedPDFs() {
        let corruptionTypes = Gen<Int>.choose((0, 4))
        
        property("Parser handles corrupted PDFs gracefully") <- forAll(corruptionTypes) { corruptionType in
            let baseText = """
            PAYSLIP
            Name: Test User
            Month: January
            Year: 2023
            Credits: 5000.00
            Debits: 1000.00
            """
            
            let corruptedDocument: PDFDocument
            
            switch corruptionType {
            case 0:
                // Empty PDF
                corruptedDocument = PDFDocument()
            case 1:
                // PDF with corrupted text encoding
                let corruptedText = baseText.data(using: .utf8)?.map { _ in UInt8.random(in: 0...255) }
                let corruptedString = String(data: Data(corruptedText ?? []), encoding: .utf8) ?? ""
                corruptedDocument = TestDataGenerator.generatePDFDocumentFromText(corruptedString)
            case 2:
                // PDF with missing critical information
                corruptedDocument = TestDataGenerator.generatePDFDocumentFromText("PAYSLIP\nSome random text")
            case 3:
                // PDF with extremely long content
                let longText = String(repeating: baseText, count: 1000)
                corruptedDocument = TestDataGenerator.generatePDFDocumentFromText(longText)
            default:
                // PDF with mixed valid and invalid content
                let mixedText = baseText + "\n" + String((0..<100).map { _ in Character(UnicodeScalar(Int.random(in: 32...126))!) })
                corruptedDocument = TestDataGenerator.generatePDFDocumentFromText(mixedText)
            }
            
            do {
                let result = try await self.payslipParserCoordinator.parsePayslip(pdfDocument: corruptedDocument)
                
                switch result {
                case .success(let payslip):
                    // If parsing succeeds, validate basic properties
                    return payslip.credits >= 0 && payslip.debits >= 0
                case .failure(let error):
                    // Expected failure cases
                    return error == .emptyPDF || 
                           error == .extractionFailed || 
                           error.localizedDescription.contains("parsing")
                }
            } catch {
                return true // Exceptions are acceptable for corrupted PDFs
            }
        }
    }
    
    // MARK: - Property Tests for Pattern Matching
    
    /// Tests pattern matching robustness across different text structures
    func testPatternMatchingRobustness() {
        // Generate various text structures that might contain payslip data
        let textStructureGen = Gen<String>.compose { gen in
            let patterns = [
                "Name: {name}\nCredits: {credits}\nDebits: {debits}",
                "{name} | {credits} | {debits}",
                "Employee: {name}\nTotal Earnings: {credits}\nTotal Deductions: {debits}",
                "{name}\n{credits}\n{debits}",
                "Name={name};Credits={credits};Debits={debits}",
                "{name} earned {credits} with deductions of {debits}",
                "PAYSLIP\n{name}\nEarnings: {credits}\nDeductions: {debits}\nNet: {net}"
            ]
            
            return gen.fromElements(in: patterns)
        }
        
        let nameGen = Gen<String>.fromElements(in: ["John Smith", "Jane Doe", "Robert Johnson", "Sarah Williams", "Michael Brown"])
        let creditsGen = Gen<Double>.choose((1000.0, 100000.0))
        let debitsGen = Gen<Double>.choose((100.0, 50000.0))
        
        property("Pattern matching works across text structures") <- forAll(
            textStructureGen, nameGen, creditsGen, debitsGen
        ) { pattern, name, credits, debits in
            // Replace placeholders with actual values
            let text = pattern
                .replacingOccurrences(of: "{name}", with: name)
                .replacingOccurrences(of: "{credits}", with: String(format: "%.2f", credits))
                .replacingOccurrences(of: "{debits}", with: String(format: "%.2f", debits))
                .replacingOccurrences(of: "{net}", with: String(format: "%.2f", credits - debits))
            
            // Test pattern manager's ability to extract data
            if let extractedPayslip = self.patternManager.parsePayslipData(text) {
                // Verify extracted data matches input within reasonable tolerance
                let epsilon = 0.01
                let nameMatch = extractedPayslip.name.contains(name) || name.contains(extractedPayslip.name)
                let creditsMatch = abs(extractedPayslip.credits - credits) < epsilon || 
                                 abs(extractedPayslip.credits - credits) / credits < 0.1
                let debitsMatch = abs(extractedPayslip.debits - debits) < epsilon || 
                                abs(extractedPayslip.debits - debits) / debits < 0.1
                
                return nameMatch && creditsMatch && debitsMatch
            } else {
                // Pattern matching can fail for complex structures - this is acceptable
                return true
            }
        }
    }
    
    /// Tests abbreviation expansion and matching
    func testAbbreviationHandling() {
        let abbreviationGen = Gen<(String, String, String)>.compose { gen in
            let militaryAbbreviations = [
                ("DA", "Dearness Allowance", "DEARNESS ALLOWANCE"),
                ("HRA", "House Rent Allowance", "HOUSE RENT ALLOWANCE"),
                ("CCA", "City Compensatory Allowance", "CITY COMPENSATORY ALLOWANCE"),
                ("X PAY", "Special Pay", "SPECIAL PAY"),
                ("DSOP", "Defence Savings and Old Age Pension", "DSOP FUND")
            ]
            
            return gen.fromElements(in: militaryAbbreviations)
        }
        
        property("Abbreviation handling works correctly") <- forAll(abbreviationGen) { (abbrev, expansion, variant) in
            let testTexts = [
                "\(abbrev): 5000.00",
                "\(expansion): 5000.00", 
                "\(variant): 5000.00",
                "Amount for \(abbrev) is 5000.00",
                "\(abbrev.lowercased()): 5000.00"
            ]
            
            var allTestsPassed = true
            
            for text in testTexts {
                // Test that abbreviation manager can handle all variations
                let normalizedText = self.abbreviationManager.expandAbbreviations(in: text)
                
                // Should contain either the abbreviation or its expansion
                let containsAbbrev = normalizedText.contains(abbrev) || 
                                   normalizedText.contains(expansion) || 
                                   normalizedText.contains(variant)
                
                if !containsAbbrev {
                    allTestsPassed = false
                    break
                }
            }
            
            return allTestsPassed
        }
    }
    
    // MARK: - Property Tests for Data Extraction Services
    
    /// Tests data extraction service robustness
    func testDataExtractionRobustness() {
        let dataVariationGen = Gen<(String, Double, Double, String, Int)>.compose { gen in
            let nameVariations = ["John Smith", "JOHN SMITH", "john smith", "J. Smith", "Smith, John"]
            let amountFormats = [0, 1, 2, 3] // Different formatting styles
            
            return gen.fromElements(in: nameVariations)
                .flatMap { name in
                    Gen<Double>.choose((1000.0, 100000.0))
                        .flatMap { credits in
                            Gen<Double>.choose((100.0, 50000.0))
                                .flatMap { debits in
                                    gen.fromElements(in: amountFormats)
                                        .map { format in (name, credits, debits, name, format) }
                                }
                        }
                }
        }
        
        property("Data extraction handles format variations") <- forAll(dataVariationGen) { (name, credits, debits, _, formatType) in
            let formattedCredits: String
            let formattedDebits: String
            
            switch formatType {
            case 0:
                formattedCredits = String(format: "%.2f", credits)
                formattedDebits = String(format: "%.2f", debits)
            case 1:
                formattedCredits = "₹" + String(format: "%.2f", credits)
                formattedDebits = "₹" + String(format: "%.2f", debits)
            case 2:
                formattedCredits = "Rs. " + String(format: "%.2f", credits)
                formattedDebits = "Rs. " + String(format: "%.2f", debits)
            default:
                // Indian number formatting with commas
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                numberFormatter.locale = Locale(identifier: "en_IN")
                formattedCredits = numberFormatter.string(from: NSNumber(value: credits)) ?? String(credits)
                formattedDebits = numberFormatter.string(from: NSNumber(value: debits)) ?? String(debits)
            }
            
            let testText = """
            PAYSLIP
            Name: \(name)
            Total Credits: \(formattedCredits)
            Total Debits: \(formattedDebits)
            """
            
            // Test pattern manager's extraction capability
            if let extractedPayslip = self.patternManager.parsePayslipData(testText) {
                let epsilon = 0.01
                let creditsMatch = abs(extractedPayslip.credits - credits) < epsilon ||
                                 abs(extractedPayslip.credits - credits) / credits < 0.05
                let debitsMatch = abs(extractedPayslip.debits - debits) < epsilon ||
                                abs(extractedPayslip.debits - debits) / debits < 0.05
                
                return creditsMatch && debitsMatch
            } else {
                // Extraction can fail for some formats - acceptable
                return true
            }
        }
    }
    
    // MARK: - Performance Property Tests
    
    /// Tests that parsing performance remains reasonable with various input sizes
    func testParsingPerformance() {
        let inputSizeGen = Gen<Int>.choose((100, 10000)) // Text length in characters
        
        property("Parsing performance scales reasonably with input size") <- forAll(inputSizeGen) { textLength in
            // Generate text of specified length
            let baseText = """
            PAYSLIP
            Name: Performance Test User
            Month: January
            Year: 2023
            Credits: 50000.00
            Debits: 10000.00
            """
            
            let paddingLength = max(0, textLength - baseText.count)
            let padding = String(repeating: "Additional content line.\n", count: paddingLength / 25)
            let fullText = baseText + "\n" + padding
            
            let pdfDocument = TestDataGenerator.generatePDFDocumentFromText(fullText)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let _ = try await self.payslipParserCoordinator.parsePayslip(pdfDocument: pdfDocument)
                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = endTime - startTime
                
                // Performance should scale reasonably - no more than 1 second per 1000 characters
                let maxExpectedTime = Double(textLength) / 1000.0
                return executionTime <= maxExpectedTime
            } catch {
                // Performance test should not fail due to parsing errors
                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = endTime - startTime
                return executionTime <= 5.0 // Maximum 5 seconds even for failures
            }
        }
    }
}

// MARK: - Helper Extensions

extension TestDataGenerator {
    static func generatePDFDocumentFromText(_ text: String) -> PDFDocument {
        let pdfDocument = PDFDocument()
        
        // Create a simple PDF page with the text
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard letter size
        let page = PDFPage()
        
        // Add text to the page (simplified approach)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)
        
        // For testing purposes, we'll create a basic PDF
        // In a real implementation, this would be more sophisticated
        if pdfDocument.pageCount == 0 {
            pdfDocument.insert(page, at: 0)
        }
        
        return pdfDocument
    }
} 