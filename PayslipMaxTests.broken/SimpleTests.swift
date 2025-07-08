import XCTest
@testable import PayslipMax

@MainActor
class SimpleTests: XCTestCase {
    func testSimpleBoolean() {
        // A very basic test that should always pass
        let testValue = true
        XCTAssertTrue(testValue, "Boolean test should pass")
    }
    
    func testStringComparison() {
        let testString = "Hello World"
        XCTAssertEqual(testString, "Hello World", "String comparison should match")
    }
    
    func testMathOperation() {
        let result = 2 + 2
        XCTAssertEqual(result, 4, "Basic math should work correctly")
    }
} 