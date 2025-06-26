import XCTest
import SwiftCheck
@testable import PayslipMax
@testable import PayslipMaxTestMocks

/// Property-based tests for payslip processing components
class PayslipPropertyTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    override func setUp() {
        super.setUp()
        // Set up any test dependencies
    }
    
    override func tearDown() {
        // Clean up after tests
        super.tearDown()
    }
    
    // MARK: - Property Tests for PayslipItem
    
    /// Tests that all PayslipItem instances maintain balance consistency
    func testPayslipBalanceConsistency() {
        // Define generators for PayslipItem properties
        let creditGen = Gen<Double>.choose((0.0, 100000.0))
        let debitGen = Gen<Double>.choose((0.0, 50000.0))
        let dsopGen = Gen<Double?>.fromOptional(Gen<Double>.choose((0.0, 10000.0)))
        let taxGen = Gen<Double?>.fromOptional(Gen<Double>.choose((0.0, 30000.0)))
        
        // Generate random but plausible PayslipItem instances
        property("PayslipItem balance calculations are consistent") <- forAll(
            creditGen, debitGen, dsopGen, taxGen
        ) { credits, debits, dsop, tax in
            // Create a PayslipItem with random values
            let payslip = PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: credits,
                debits: debits,
                dsop: dsop,
                tax: tax,
                name: "Property Test User",
                accountNumber: "TEST-ACCOUNT",
                panNumber: "TEST-PAN"
            )
            
            // Property: Net amount should equal credits minus debits
            let expectedNet = credits - debits
            let actualNet = payslip.netAmount
            
            // Property: Total deductions should equal debits + dsop (if present) + tax (if present)
            let expectedTotalDeductions = debits + (dsop ?? 0.0) + (tax ?? 0.0)
            let actualTotalDeductions = payslip.totalDeductions
            
            // Property: Available balance should equal credits minus total deductions
            let expectedAvailable = credits - expectedTotalDeductions
            let actualAvailable = payslip.availableBalance
            
            // Validate all properties within a small epsilon for floating point comparison
            let epsilon = 0.001
            return (abs(expectedNet - actualNet) < epsilon) &&
                   (abs(expectedTotalDeductions - actualTotalDeductions) < epsilon) &&
                   (abs(expectedAvailable - actualAvailable) < epsilon)
        }
    }
    
    /// Tests that PayslipItem encoding and decoding preserves all data
    func testPayslipCodableRoundtrip() {
        // Define generators for PayslipItem properties
        let monthGen = Gen<String>.fromElements(in: ["January", "February", "March", "April", "May", "June",
                                                    "July", "August", "September", "October", "November", "December"])
        let yearGen = Gen<Int>.choose((2000, 2030))
        let creditGen = Gen<Double>.choose((0.0, 100000.0))
        let debitGen = Gen<Double>.choose((0.0, 50000.0))
        let dsopGen = Gen<Double?>.fromOptional(Gen<Double>.choose((0.0, 10000.0)))
        let taxGen = Gen<Double?>.fromOptional(Gen<Double>.choose((0.0, 30000.0)))
        let nameGen = Gen<String>.fromElements(in: ["John Smith", "Jane Doe", "Robert Johnson", "Sarah Williams"])
        
        // Property: Encoding and then decoding a PayslipItem should yield an equivalent PayslipItem
        property("PayslipItem encoding/decoding preserves data") <- forAll(
            monthGen, yearGen, creditGen, debitGen, dsopGen, taxGen, nameGen
        ) { month, year, credits, debits, dsop, tax, name in
            // Create a PayslipItem with random values
            let originalPayslip = PayslipItem(
                id: UUID(),
                month: month,
                year: year,
                credits: credits,
                debits: debits,
                dsop: dsop,
                tax: tax,
                name: name,
                accountNumber: "ACCT-\(Int.random(in: 1000...9999))",
                panNumber: "PAN-\(Int.random(in: 10000...99999))"
            )
            
            // Add some random credit and debit breakdowns
            var creditBreakdown: [String: Double] = [:]
            var debitBreakdown: [String: Double] = [:]
            
            creditBreakdown["Base Pay"] = credits * 0.7
            creditBreakdown["Allowances"] = credits * 0.3
            
            debitBreakdown["Insurance"] = debits * 0.2
            debitBreakdown["Other Deductions"] = debits * 0.8
            
            originalPayslip.creditBreakdown = creditBreakdown
            originalPayslip.debitBreakdown = debitBreakdown
            
            do {
                // Encode to data
                let encoder = JSONEncoder()
                let data = try encoder.encode(originalPayslip)
                
                // Decode back to PayslipItem
                let decoder = JSONDecoder()
                let decodedPayslip = try decoder.decode(PayslipItem.self, from: data)
                
                // Verify key properties are maintained
                return originalPayslip.id == decodedPayslip.id &&
                       originalPayslip.month == decodedPayslip.month &&
                       originalPayslip.year == decodedPayslip.year &&
                       abs(originalPayslip.credits - decodedPayslip.credits) < 0.001 &&
                       abs(originalPayslip.debits - decodedPayslip.debits) < 0.001 &&
                       (originalPayslip.dsop == nil && decodedPayslip.dsop == nil ||
                        abs((originalPayslip.dsop ?? 0) - (decodedPayslip.dsop ?? 0)) < 0.001) &&
                       (originalPayslip.tax == nil && decodedPayslip.tax == nil ||
                        abs((originalPayslip.tax ?? 0) - (decodedPayslip.tax ?? 0)) < 0.001) &&
                       originalPayslip.name == decodedPayslip.name &&
                       originalPayslip.accountNumber == decodedPayslip.accountNumber &&
                       originalPayslip.panNumber == decodedPayslip.panNumber &&
                       originalPayslip.creditBreakdown?.count == decodedPayslip.creditBreakdown?.count &&
                       originalPayslip.debitBreakdown?.count == decodedPayslip.debitBreakdown?.count
            } catch {
                return false
            }
        }
    }
    
    // MARK: - Property Tests for Parsing
    
    /// Tests that generated payslips are parsed correctly
    func testPayslipParsingConsistency() {
        // Create a range of test payslips across different domains
        property("Generated payslips can be parsed correctly") <- forAll(
            Gen<Int>.choose((0, 4)) // Generate random payslip type index
        ) { payslipTypeIndex in
            // Get a test payslip based on the random index
            let payslip: PayslipItem
            let mockPDFService = MockPDFService()
            
            switch payslipTypeIndex {
            case 0:
                payslip = MilitaryPayslipGenerator.standardMilitaryPayslip()
            case 1:
                payslip = CorporatePayslipGenerator.standardCorporatePayslip()
            case 2:
                payslip = GovernmentPayslipGenerator.standardGovernmentPayslip()
            case 3:
                payslip = PublicSectorPayslipGenerator.standardPublicSectorPayslip()
            default:
                // Include some edge cases
                payslip = AnomalousPayslipGenerator.payslipWithSpecialCharacters()
            }
            
            // Generate a PDF for this payslip
            let pdfDocument = TestDataGenerator.generatePDFDocument(
                forPayslip: payslip,
                withTitle: "Property Test - \(payslip.name)"
            )
            
            // Create mock PDFData
            guard let pdfData = pdfDocument.dataRepresentation() else {
                return false
            }
            
            // Configure the mock PDF service
            mockPDFService.pdfDataToReturn = pdfData
            
            // Create parsing coordinator with the mock PDF service
            let mockEncryptionService = MockEncryptionService()
            let parser = PayslipParserRegistry.generalParser
            let coordinator = PDFParsingOrchestrator(
                pdfService: mockPDFService,
                encryptionService: mockEncryptionService
            )
            
            do {
                // Attempt to parse the generated PDF
                let parsedPayslip = try coordinator.parsePayslipData(from: payslip.id.uuidString, using: parser)
                
                // Verify core financial information is preserved
                let deltaPercent = 0.05 // Allow 5% deviation for parsing approximations
                let creditsDeviation = abs(payslip.credits - parsedPayslip.credits) / payslip.credits
                let debitsDeviation = abs(payslip.debits - parsedPayslip.debits) / payslip.debits
                
                let creditsMatch = creditsDeviation <= deltaPercent
                let debitsMatch = debitsDeviation <= deltaPercent
                
                // Month, year, and other key fields should also match
                let yearMatch = payslip.year == parsedPayslip.year
                let monthMatch = payslip.month.lowercased().contains(parsedPayslip.month.lowercased()) ||
                                parsedPayslip.month.lowercased().contains(payslip.month.lowercased())
                
                return creditsMatch && debitsMatch && yearMatch && monthMatch
            } catch {
                // If parsing fails, the property test fails
                return false
            }
        }
    }
    
    /// Tests that parsing is resilient to various text formats and layouts
    func testPayslipParsingResilience() {
        // Define generators for different text formats and layouts
        let formatGen = Gen<Int>.choose((0, 2)) // 0: standard, 1: mixed case, 2: extra whitespace
        
        property("Payslip parsing is resilient to text format variations") <- forAll(
            formatGen
        ) { formatType in
            // Create a basic payslip with simple values
            let payslip = PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 500.0,
                tax: 1200.0,
                name: "Property Test User",
                accountNumber: "TEST-ACCOUNT",
                panNumber: "TEST-PAN"
            )
            
            // Create a payslip PDF with format variations
            let pdfContent: String
            switch formatType {
            case 0:
                // Standard format
                pdfContent = """
                PAYSLIP
                Name: Property Test User
                Month: January
                Year: 2023
                
                CREDITS: 5000.00
                DEBITS: 1000.00
                """
            case 1:
                // Mixed case format
                pdfContent = """
                pAySlIp
                name: Property Test User
                MoNtH: January
                year: 2023
                
                Credits: 5000.00
                debits: 1000.00
                """
            case 2:
                // Extra whitespace format
                pdfContent = """
                PAYSLIP
                Name:     Property Test User
                Month:   January  
                Year:  2023
                
                CREDITS:    5000.00  
                DEBITS:   1000.00  
                """
            default:
                pdfContent = ""
            }
            
            let mockPDFService = MockPDFService()
            let mockDocument = TestDataGenerator.generatePDFDocumentFromText(pdfContent)
            
            guard let pdfData = mockDocument.dataRepresentation() else {
                return false
            }
            
            // Configure the mock PDF service
            mockPDFService.pdfDataToReturn = pdfData
            
            // Create parsing coordinator
            let mockEncryptionService = MockEncryptionService()
            let parser = PayslipParserRegistry.generalParser
            let coordinator = PDFParsingOrchestrator(
                pdfService: mockPDFService,
                encryptionService: mockEncryptionService
            )
            
            do {
                // Attempt to parse the generated PDF
                let parsedPayslip = try coordinator.parsePayslipData(from: payslip.id.uuidString, using: parser)
                
                // Verify key information is parsed correctly regardless of format
                return parsedPayslip.month.lowercased().contains("january") &&
                       parsedPayslip.year == 2023 &&
                       abs(parsedPayslip.credits - 5000.0) < 0.01 &&
                       abs(parsedPayslip.debits - 1000.0) < 0.01
            } catch {
                return false
            }
        }
    }
    
    // MARK: - Property Tests for Edge Cases
    
    /// Tests correct behavior of PayslipItem with extreme numerical values
    func testPayslipExtremeValues() {
        // Test with extreme values to find bugs in calculations
        property("PayslipItem handles extreme values correctly") <- forAll(
            Gen<Double>.choose((0.0, Double.greatestFiniteMagnitude / 3)) // Large but safe value
        ) { largeValue in
            // Create payslip with extreme values
            let payslip = PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: largeValue,
                debits: largeValue / 2,
                dsop: largeValue / 10,
                tax: largeValue / 5,
                name: "Property Test User",
                accountNumber: "TEST-ACCOUNT",
                panNumber: "TEST-PAN"
            )
            
            // Check that calculations don't overflow or produce incorrect results
            let expectedNet = largeValue - (largeValue / 2)
            let expectedTotalDeductions = (largeValue / 2) + (largeValue / 10) + (largeValue / 5)
            let expectedAvailable = largeValue - expectedTotalDeductions
            
            // Values should match expectations and be finite (not NaN or infinity)
            return abs(expectedNet - payslip.netAmount) / largeValue < 0.001 &&
                   abs(expectedTotalDeductions - payslip.totalDeductions) / largeValue < 0.001 &&
                   abs(expectedAvailable - payslip.availableBalance) / largeValue < 0.001 &&
                   payslip.netAmount.isFinite &&
                   payslip.totalDeductions.isFinite &&
                   payslip.availableBalance.isFinite
        }
    }
    
    /// Tests that PayslipItem schema migration preserves data
    func testSchemaMigration() {
        property("PayslipItem schema migration preserves data") <- forAll(
            Gen<Int>.choose((1, PayslipItem.SchemaVersion.current.rawValue))
        ) { startSchemaVersion in
            // Create a PayslipItem with a specific schema version
            let payslip = PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 500.0,
                tax: 1200.0,
                name: "Property Test User",
                accountNumber: "TEST-ACCOUNT",
                panNumber: "TEST-PAN",
                schemaVersion: PayslipItem.SchemaVersion(rawValue: startSchemaVersion) ?? .v1
            )
            
            // Migrate to current schema
            let migratedPayslip = payslip.migratedToCurrentSchema()
            
            // Core data should be preserved across migrations
            return migratedPayslip.schemaVersion == .current &&
                   migratedPayslip.id == payslip.id &&
                   migratedPayslip.month == payslip.month &&
                   migratedPayslip.year == payslip.year &&
                   abs(migratedPayslip.credits - payslip.credits) < 0.001 &&
                   abs(migratedPayslip.debits - payslip.debits) < 0.001 &&
                   abs((migratedPayslip.dsop ?? 0) - (payslip.dsop ?? 0)) < 0.001 &&
                   abs((migratedPayslip.tax ?? 0) - (payslip.tax ?? 0)) < 0.001 &&
                   migratedPayslip.name == payslip.name
        }
    }
} 