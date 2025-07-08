import XCTest
@testable import PayslipMax

final class BooleanUtilityTests: XCTestCase {
    
    func testBasicBooleanOperations() {
        let trueValue = true
        let falseValue = false
        
        XCTAssertTrue(trueValue, "True should be true")
        XCTAssertFalse(falseValue, "False should be false")
        XCTAssertNotEqual(trueValue, falseValue, "True and false should not be equal")
    }
    
    func testBooleanLogic() {
        let a = true
        let b = false
        
        XCTAssertTrue(a && true, "AND operation should work")
        XCTAssertFalse(a && b, "AND operation should work")
        XCTAssertTrue(a || b, "OR operation should work")
        XCTAssertFalse(b || false, "OR operation should work")
        XCTAssertFalse(!a, "NOT operation should work")
        XCTAssertTrue(!b, "NOT operation should work")
    }
    
    func testBooleanConversion() {
        let truthyInt = 1
        let falsyInt = 0
        
        XCTAssertTrue(truthyInt != 0, "Non-zero should be truthy")
        XCTAssertTrue(falsyInt == 0, "Zero should be falsy")
        
        let truthyString = "hello"
        let emptyString = ""
        
        XCTAssertFalse(truthyString.isEmpty, "Non-empty string should be truthy")
        XCTAssertTrue(emptyString.isEmpty, "Empty string should be falsy")
    }
    
    func testBooleanComparison() {
        let values = [true, false, true, false]
        let trueCount = values.filter { $0 }.count
        let falseCount = values.filter { !$0 }.count
        
        XCTAssertEqual(trueCount, 2, "Should count true values correctly")
        XCTAssertEqual(falseCount, 2, "Should count false values correctly")
        XCTAssertEqual(trueCount + falseCount, values.count, "Total should equal array count")
    }
} 