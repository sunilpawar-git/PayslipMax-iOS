import XCTest
@testable import Payslip_Max

final class PayslipItemTests: XCTestCase {
    var sut: PayslipItem!
    
    override func setUp() {
        super.setUp()
        // Create a test PayslipItem with sample data
        sut = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            rank: "Captain",
            serviceNumber: "12345",
            basicPay: 50000.0,
            allowances: [
                Allowance(name: "Housing", amount: 10000),
                Allowance(name: "Transport", amount: 5000)
            ],
            deductions: [
                Deduction(name: "Tax", amount: 15000),
                Deduction(name: "Insurance", amount: 2000)
            ],
            netPay: 48000.0,
            postingDetails: PostingDetails(
                unit: "Test Unit",
                location: "Test Location",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 365)
            )
        )
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testPayslipItemInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.rank, "Captain")
        XCTAssertEqual(sut.serviceNumber, "12345")
        XCTAssertEqual(sut.basicPay, 50000.0)
        XCTAssertEqual(sut.netPay, 48000.0)
    }
    
    func testAllowancesCalculation() {
        let totalAllowances = sut.allowances.reduce(0) { $0 + $1.amount }
        XCTAssertEqual(totalAllowances, 15000.0)
    }
    
    func testDeductionsCalculation() {
        let totalDeductions = sut.deductions.reduce(0) { $0 + $1.amount }
        XCTAssertEqual(totalDeductions, 17000.0)
    }
    
    func testPostingDetails() {
        XCTAssertNotNil(sut.postingDetails)
        XCTAssertEqual(sut.postingDetails?.unit, "Test Unit")
        XCTAssertEqual(sut.postingDetails?.location, "Test Location")
    }
    
    func testPayCalculation() {
        let totalAllowances = sut.allowances.reduce(0) { $0 + $1.amount }
        let totalDeductions = sut.deductions.reduce(0) { $0 + $1.amount }
        let expectedNet = sut.basicPay + totalAllowances - totalDeductions
        XCTAssertEqual(sut.netPay, expectedNet, accuracy: 0.01)
    }
} 