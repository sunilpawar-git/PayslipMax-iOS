import XCTest
@testable import PayslipMax

/// Tests for PayslipMigrationService
/// Validates conversion of legacy PayslipItem to SimplifiedPayslip
final class PayslipMigrationServiceTests: XCTestCase {
    
    var migrationService: PayslipMigrationService!
    
    override func setUp() {
        super.setUp()
        migrationService = PayslipMigrationService()
    }
    
    override func tearDown() {
        migrationService = nil
        super.tearDown()
    }
    
    // MARK: - Core Migration Tests
    
    func testBasicMigration() {
        // Create legacy PayslipItem
        let legacyPayslip = PayslipItem(
            month: "August",
            year: 2025,
            credits: 275015,
            debits: 102029,
            dsop: 40000,
            tax: 47624,
            earnings: [
                "BPAY": 144700,
                "DA": 88110,
                "MSP": 15500,
                "RH12": 21125,
                "TPTA": 3600,
                "TPTADA": 1980
            ],
            deductions: [
                "DSOP": 40000,
                "AGIF": 12500,
                "ITAX": 47624,
                "EHCESS": 1905
            ],
            name: "Sunil Suresh Pawar"
        )
        
        // Migrate
        let simplifiedPayslip = migrationService.migrate(legacyPayslip)
        
        // Verify core earnings
        XCTAssertEqual(simplifiedPayslip.basicPay, 144700, "BPAY should be migrated")
        XCTAssertEqual(simplifiedPayslip.dearnessAllowance, 88110, "DA should be migrated")
        XCTAssertEqual(simplifiedPayslip.militaryServicePay, 15500, "MSP should be migrated")
        XCTAssertEqual(simplifiedPayslip.grossPay, 275015, "Gross Pay should match credits")
        
        // Verify core deductions
        XCTAssertEqual(simplifiedPayslip.dsop, 40000, "DSOP should be migrated")
        XCTAssertEqual(simplifiedPayslip.agif, 12500, "AGIF should be migrated")
        XCTAssertEqual(simplifiedPayslip.incomeTax, 47624, "Income Tax should be migrated")
        XCTAssertEqual(simplifiedPayslip.totalDeductions, 102029, "Total Deductions should match debits")
        
        // Verify calculated fields
        let expectedOtherEarnings = 275015.0 - (144700.0 + 88110.0 + 15500.0)
        XCTAssertEqual(simplifiedPayslip.otherEarnings, expectedOtherEarnings, accuracy: 1.0, "Other Earnings should be calculated")
        
        let expectedOtherDeductions = 102029.0 - (40000.0 + 12500.0 + 47624.0)
        XCTAssertEqual(simplifiedPayslip.otherDeductions, expectedOtherDeductions, accuracy: 1.0, "Other Deductions should be calculated")
        
        // Verify net remittance
        XCTAssertEqual(simplifiedPayslip.netRemittance, 172986, accuracy: 1.0, "Net Remittance should be calculated")
    }
    
    func testBreakdownMigration() {
        // Create legacy PayslipItem with various codes
        let legacyPayslip = PayslipItem(
            month: "August",
            year: 2025,
            credits: 100000,
            debits: 30000,
            dsop: 10000,
            tax: 15000,
            earnings: [
                "BPAY": 50000,
                "DA": 30000,
                "MSP": 10000,
                "RH12": 5000,
                "CEA": 3000,
                "HRA": 2000
            ],
            deductions: [
                "DSOP": 10000,
                "AGIF": 5000,
                "ITAX": 15000
            ]
        )
        
        // Migrate
        let simplifiedPayslip = migrationService.migrate(legacyPayslip)
        
        // Verify other earnings breakdown contains non-core codes
        XCTAssertTrue(simplifiedPayslip.otherEarningsBreakdown.keys.contains("RH12"), "RH12 should be in breakdown")
        XCTAssertTrue(simplifiedPayslip.otherEarningsBreakdown.keys.contains("CEA"), "CEA should be in breakdown")
        XCTAssertTrue(simplifiedPayslip.otherEarningsBreakdown.keys.contains("HRA"), "HRA should be in breakdown")
        
        // Verify breakdown doesn't contain core codes
        XCTAssertFalse(simplifiedPayslip.otherEarningsBreakdown.keys.contains("BPAY"), "BPAY should not be in breakdown")
        XCTAssertFalse(simplifiedPayslip.otherEarningsBreakdown.keys.contains("DA"), "DA should not be in breakdown")
        XCTAssertFalse(simplifiedPayslip.otherEarningsBreakdown.keys.contains("MSP"), "MSP should not be in breakdown")
    }
    
    func testMigrationConfidence() {
        let legacyPayslip = PayslipItem(
            month: "August",
            year: 2025,
            credits: 100000,
            debits: 30000
        )
        
        let simplifiedPayslip = migrationService.migrate(legacyPayslip)
        
        // Migrated data should have 80% confidence
        XCTAssertEqual(simplifiedPayslip.parsingConfidence, 0.8, "Migrated data should have 80% confidence")
        XCTAssertEqual(simplifiedPayslip.source, "Migrated from Legacy", "Source should indicate migration")
        XCTAssertFalse(simplifiedPayslip.isEdited, "Should not be marked as edited")
    }
    
    func testBulkMigration() {
        // Create multiple legacy payslips
        let legacyPayslips = [
            PayslipItem(month: "January", year: 2025, credits: 100000, debits: 30000),
            PayslipItem(month: "February", year: 2025, credits: 105000, debits: 32000),
            PayslipItem(month: "March", year: 2025, credits: 110000, debits: 35000)
        ]
        
        // Migrate all
        let simplifiedPayslips = migrationService.migrateAll(legacyPayslips)
        
        XCTAssertEqual(simplifiedPayslips.count, 3, "Should migrate all payslips")
        XCTAssertEqual(simplifiedPayslips[0].month, "January", "First payslip should be January")
        XCTAssertEqual(simplifiedPayslips[1].month, "February", "Second payslip should be February")
        XCTAssertEqual(simplifiedPayslips[2].month, "March", "Third payslip should be March")
    }
}

