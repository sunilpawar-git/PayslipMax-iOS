import XCTest

class BasicTests: XCTestCase {
    
    func testAddition() {
        XCTAssertEqual(1 + 1, 2, "1 + 1 should equal 2")
    }
    
    func testSubtraction() {
        XCTAssertEqual(3 - 1, 2, "3 - 1 should equal 2")
    }
    
    func testMultiplication() {
        XCTAssertEqual(2 * 2, 4, "2 * 2 should equal 4")
    }
    
    func testDivision() {
        XCTAssertEqual(4 / 2, 2, "4 / 2 should equal 2")
    }
} 