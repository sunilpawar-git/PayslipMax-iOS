import XCTest
@testable import PayslipMax

final class ArrayUtilityTests: XCTestCase {
    
    func testBasicArrayOperations() {
        let numbers = [1, 2, 3, 4, 5]
        XCTAssertEqual(numbers.count, 5, "Array count should be correct")
        XCTAssertEqual(numbers.first, 1, "Array first element should be correct")
        XCTAssertEqual(numbers.last, 5, "Array last element should be correct")
        
        let empty: [Int] = []
        XCTAssertTrue(empty.isEmpty, "Empty array should be empty")
    }
    
    func testArrayFiltering() {
        let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let evenNumbers = numbers.filter { $0 % 2 == 0 }
        XCTAssertEqual(evenNumbers, [2, 4, 6, 8, 10], "Array filtering should work")
        
        let greaterThanFive = numbers.filter { $0 > 5 }
        XCTAssertEqual(greaterThanFive, [6, 7, 8, 9, 10], "Array filtering with condition should work")
    }
    
    func testArrayMapping() {
        let numbers = [1, 2, 3, 4, 5]
        let doubled = numbers.map { $0 * 2 }
        XCTAssertEqual(doubled, [2, 4, 6, 8, 10], "Array mapping should work")
        
        let strings = numbers.map { String($0) }
        XCTAssertEqual(strings, ["1", "2", "3", "4", "5"], "Array mapping to different type should work")
    }
    
    func testArrayReduction() {
        let numbers = [1, 2, 3, 4, 5]
        let sum = numbers.reduce(0, +)
        XCTAssertEqual(sum, 15, "Array reduction should work")
        
        let product = numbers.reduce(1, *)
        XCTAssertEqual(product, 120, "Array reduction with multiplication should work")
    }
    
    func testArrayContains() {
        let fruits = ["apple", "banana", "orange", "grape"]
        XCTAssertTrue(fruits.contains("apple"), "Array contains should work")
        XCTAssertFalse(fruits.contains("kiwi"), "Array contains should work for non-existing")
        
        let numbers = [10, 20, 30, 40, 50]
        XCTAssertTrue(numbers.contains(30), "Array contains with numbers should work")
    }
    
    func testArraySorting() {
        let unsorted = [5, 2, 8, 1, 9, 3]
        let sorted = unsorted.sorted()
        XCTAssertEqual(sorted, [1, 2, 3, 5, 8, 9], "Array sorting should work")
        
        let reversed = sorted.reversed()
        XCTAssertEqual(Array(reversed), [9, 8, 5, 3, 2, 1], "Array reversal should work")
    }
} 