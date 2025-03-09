import XCTest
@testable import PayslipStandaloneTests

final class StandalonePayslipItemTests: XCTestCase {
    
    func testPayslipItemInitialization() {
        // Given
        let id = UUID()
        let month = "February"
        let year = 2024
        let credits = 6000.0
        let debits = 1500.0
        let dspof = 300.0
        let tax = 900.0
        let location = "San Francisco"
        let name = "Jane Smith"
        let accountNumber = "0987654321"
        let panNumber = "ZYXWV9876G"
        let timestamp = Date()
        
        // When
        let payslip = StandalonePayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dspof: dspof,
            tax: tax,
            location: location,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(payslip.id, id)
        XCTAssertEqual(payslip.month, month)
        XCTAssertEqual(payslip.year, year)
        XCTAssertEqual(payslip.credits, credits)
        XCTAssertEqual(payslip.debits, debits)
        XCTAssertEqual(payslip.dspof, dspof)
        XCTAssertEqual(payslip.tax, tax)
        XCTAssertEqual(payslip.location, location)
        XCTAssertEqual(payslip.name, name)
        XCTAssertEqual(payslip.accountNumber, accountNumber)
        XCTAssertEqual(payslip.panNumber, panNumber)
        XCTAssertEqual(payslip.timestamp, timestamp)
    }
    
    func testPayslipItemInitializationWithDefaultValues() {
        // Given
        let month = "March"
        let year = 2024
        let credits = 7000.0
        let debits = 2000.0
        let dspof = 400.0
        let tax = 1000.0
        let location = "Chicago"
        let name = "Bob Johnson"
        let accountNumber = "5555555555"
        let panNumber = "PQRST5678H"
        
        // When - using default values for id and timestamp
        let payslip = StandalonePayslipItem(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dspof: dspof,
            tax: tax,
            location: location,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber
        )
        
        // Then
        XCTAssertNotNil(payslip.id, "ID should be auto-generated")
        XCTAssertEqual(payslip.month, month)
        XCTAssertEqual(payslip.year, year)
        XCTAssertEqual(payslip.credits, credits)
        XCTAssertEqual(payslip.debits, debits)
        XCTAssertEqual(payslip.dspof, dspof)
        XCTAssertEqual(payslip.tax, tax)
        XCTAssertEqual(payslip.location, location)
        XCTAssertEqual(payslip.name, name)
        XCTAssertEqual(payslip.accountNumber, accountNumber)
        XCTAssertEqual(payslip.panNumber, panNumber)
        XCTAssertNotNil(payslip.timestamp, "Timestamp should be auto-generated")
    }
    
    func testSamplePayslipItem() {
        // When
        let sample = StandalonePayslipItem.sample()
        
        // Then
        XCTAssertNotNil(sample.id)
        XCTAssertEqual(sample.month, "January")
        XCTAssertEqual(sample.year, 2023)
        XCTAssertEqual(sample.credits, 5000.0)
        XCTAssertEqual(sample.debits, 1000.0)
        XCTAssertEqual(sample.dspof, 200.0)
        XCTAssertEqual(sample.tax, 800.0)
        XCTAssertEqual(sample.location, "New York")
        XCTAssertEqual(sample.name, "John Doe")
        XCTAssertEqual(sample.accountNumber, "1234567890")
        XCTAssertEqual(sample.panNumber, "ABCDE1234F")
        XCTAssertNotNil(sample.timestamp)
    }
    
    func testCodable() {
        // Given
        let original = StandalonePayslipItem.sample()
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(StandalonePayslipItem.self, from: data)
            
            // Then
            XCTAssertEqual(decoded.id, original.id)
            XCTAssertEqual(decoded.month, original.month)
            XCTAssertEqual(decoded.year, original.year)
            XCTAssertEqual(decoded.credits, original.credits)
            XCTAssertEqual(decoded.debits, original.debits)
            XCTAssertEqual(decoded.dspof, original.dspof)
            XCTAssertEqual(decoded.tax, original.tax)
            XCTAssertEqual(decoded.location, original.location)
            XCTAssertEqual(decoded.name, original.name)
            XCTAssertEqual(decoded.accountNumber, original.accountNumber)
            XCTAssertEqual(decoded.panNumber, original.panNumber)
        } catch {
            XCTFail("Failed to encode/decode PayslipItem: \(error)")
        }
    }
    
    func testCodableWithCustomDateFormat() {
        // Given
        var original = StandalonePayslipItem.sample()
        let customDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        original.timestamp = customDate
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(StandalonePayslipItem.self, from: data)
            
            // Then
            XCTAssertEqual(decoded.timestamp, customDate, "Date should be encoded and decoded correctly")
        } catch {
            XCTFail("Failed to encode/decode PayslipItem with custom date: \(error)")
        }
    }
    
    func testEquality() {
        // Given
        let id = UUID()
        let timestamp = Date()
        
        let payslip1 = StandalonePayslipItem(
            id: id,
            month: "April",
            year: 2024,
            credits: 8000.0,
            debits: 2500.0,
            dspof: 500.0,
            tax: 1200.0,
            location: "Boston",
            name: "Alice Brown",
            accountNumber: "9876543210",
            panNumber: "LMNOP4321Q",
            timestamp: timestamp
        )
        
        let payslip2 = StandalonePayslipItem(
            id: id,
            month: "April",
            year: 2024,
            credits: 8000.0,
            debits: 2500.0,
            dspof: 500.0,
            tax: 1200.0,
            location: "Boston",
            name: "Alice Brown",
            accountNumber: "9876543210",
            panNumber: "LMNOP4321Q",
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(payslip1.id, payslip2.id)
        XCTAssertEqual(payslip1.month, payslip2.month)
        XCTAssertEqual(payslip1.year, payslip2.year)
        XCTAssertEqual(payslip1.credits, payslip2.credits)
        XCTAssertEqual(payslip1.debits, payslip2.debits)
        XCTAssertEqual(payslip1.dspof, payslip2.dspof)
        XCTAssertEqual(payslip1.tax, payslip2.tax)
        XCTAssertEqual(payslip1.location, payslip2.location)
        XCTAssertEqual(payslip1.name, payslip2.name)
        XCTAssertEqual(payslip1.accountNumber, payslip2.accountNumber)
        XCTAssertEqual(payslip1.panNumber, payslip2.panNumber)
        XCTAssertEqual(payslip1.timestamp, payslip2.timestamp)
    }
} 