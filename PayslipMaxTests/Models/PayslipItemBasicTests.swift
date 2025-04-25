import XCTest
import SwiftData
@testable import PayslipMax

final class PayslipItemBasicTests: XCTestCase {
    
    override func setUpWithError() throws {
        super.setUp()
    }
    
    override func tearDownWithError() throws {
        super.tearDown()
    }
    
    func testPayslipItemBasicProperties() {
        // Create a test payslip
        let payslip = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        // Verify properties
        XCTAssertEqual(payslip.month, "January")
        XCTAssertEqual(payslip.year, 2023)
        XCTAssertEqual(payslip.credits, 5000.0)
        XCTAssertEqual(payslip.debits, 1000.0)
        XCTAssertEqual(payslip.dsop, 300.0)
        XCTAssertEqual(payslip.tax, 800.0)
        XCTAssertEqual(payslip.name, "John Doe")
        XCTAssertEqual(payslip.accountNumber, "XXXX1234")
        XCTAssertEqual(payslip.panNumber, "ABCDE1234F")
    }
    
    func testPayslipItemID() {
        // Create two test payslips
        let payslip1 = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        let payslip2 = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        // Verify each payslip has a unique ID
        XCTAssertNotEqual(payslip1.id, payslip2.id, "Each payslip should have a unique ID")
    }
    
    func testPayslipItemEquality() {
        // Create a test payslip
        let payslip1 = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        // Create a separate payslip with same values but different ID
        let payslip2 = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
        
        // Test equality based on properties (if Equatable is implemented)
        if let equatable1 = payslip1 as? any Equatable, let equatable2 = payslip2 as? any Equatable {
            XCTAssertNotEqual(equatable1, equatable2, "Payslips with different IDs should not be equal")
        }
        
        // Alternative verification comparing properties
        XCTAssertEqual(payslip1.month, payslip2.month)
        XCTAssertEqual(payslip1.year, payslip2.year)
        XCTAssertEqual(payslip1.credits, payslip2.credits)
        XCTAssertEqual(payslip1.debits, payslip2.debits)
        XCTAssertEqual(payslip1.dsop, payslip2.dsop)
        XCTAssertEqual(payslip1.tax, payslip2.tax)
        XCTAssertEqual(payslip1.name, payslip2.name)
        XCTAssertEqual(payslip1.accountNumber, payslip2.accountNumber)
        XCTAssertEqual(payslip1.panNumber, payslip2.panNumber)
    }
    
    func testPayslipItemDefaults() {
        // Test initialization with default values where applicable
        
        // Create a payslip with minimal information
        let minimalPayslip = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            name: "John Doe"
        )
        
        // Verify properties
        XCTAssertEqual(minimalPayslip.month, "January")
        XCTAssertEqual(minimalPayslip.year, 2023)
        XCTAssertEqual(minimalPayslip.credits, 5000.0)
        XCTAssertEqual(minimalPayslip.debits, 1000.0)
        XCTAssertEqual(minimalPayslip.name, "John Doe")
        
        // Check if other properties have default values
        // The actual behavior depends on how PayslipItem is implemented
        if let dsopValue = minimalPayslip.value(forKey: "dsop") as? Double {
            XCTAssertEqual(dsopValue, 0.0, "DSOP should default to 0.0")
        }
        
        if let taxValue = minimalPayslip.value(forKey: "tax") as? Double {
            XCTAssertEqual(taxValue, 0.0, "Tax should default to 0.0")
        }
    }
} 