import XCTest
@testable import Payslip_Max

final class CITestTests: XCTestCase {
    var sut: CITest!
    
    override func setUp() {
        super.setUp()
        sut = CITest()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testTestFunction() {
        XCTAssertEqual(sut.testFunction(), "CI Test Successful")
    }
    
    func testProcessValue() {
        XCTAssertEqual(sut.processValue(5), 10)
        XCTAssertEqual(sut.processValue(0), 0)
        XCTAssertEqual(sut.processValue(-1), 0)
    }
} 