import XCTest

/// Ultra-simple test to verify basic test infrastructure works
final class SimpleArithmeticTest: XCTestCase {

    func testTwoPlusTwo() {
        XCTAssertEqual(2 + 2, 4)
    }

    func testStringEquality() {
        XCTAssertEqual("hello", "hello")
    }

    func testArrayCount() {
        let array = [1, 2, 3]
        XCTAssertEqual(array.count, 3)
    }
}
