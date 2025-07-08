import XCTest
@testable import PayslipMax

final class SetUtilityTests: XCTestCase {
    
    func testBasicSetOperations() {
        var numbers: Set<Int> = [1, 2, 3, 4, 5]
        
        XCTAssertEqual(numbers.count, 5, "Set count should be correct")
        XCTAssertTrue(numbers.contains(3), "Set should contain element")
        XCTAssertFalse(numbers.contains(6), "Set should not contain non-existing element")
        
        numbers.insert(6)
        XCTAssertEqual(numbers.count, 6, "Set count should update after insertion")
        XCTAssertTrue(numbers.contains(6), "Newly inserted element should be in set")
    }
    
    func testSetUniqueness() {
        let duplicates = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4]
        let uniqueSet = Set(duplicates)
        
        XCTAssertEqual(uniqueSet.count, 4, "Set should remove duplicates")
        XCTAssertTrue(uniqueSet.contains(1), "Set should contain unique elements")
        XCTAssertTrue(uniqueSet.contains(2), "Set should contain unique elements")
        XCTAssertTrue(uniqueSet.contains(3), "Set should contain unique elements")
        XCTAssertTrue(uniqueSet.contains(4), "Set should contain unique elements")
    }
    
    func testSetUnion() {
        let set1: Set<String> = ["apple", "banana", "cherry"]
        let set2: Set<String> = ["banana", "date", "elderberry"]
        
        let union = set1.union(set2)
        XCTAssertEqual(union.count, 5, "Union should contain all unique elements")
        XCTAssertTrue(union.contains("apple"), "Union should contain elements from first set")
        XCTAssertTrue(union.contains("date"), "Union should contain elements from second set")
        XCTAssertTrue(union.contains("banana"), "Union should contain common elements once")
    }
    
    func testSetIntersection() {
        let set1: Set<Int> = [1, 2, 3, 4, 5]
        let set2: Set<Int> = [3, 4, 5, 6, 7]
        
        let intersection = set1.intersection(set2)
        XCTAssertEqual(intersection.count, 3, "Intersection should contain common elements")
        XCTAssertTrue(intersection.contains(3), "Intersection should contain common elements")
        XCTAssertTrue(intersection.contains(4), "Intersection should contain common elements")
        XCTAssertTrue(intersection.contains(5), "Intersection should contain common elements")
        XCTAssertFalse(intersection.contains(1), "Intersection should not contain unique elements")
    }
    
    func testSetDifference() {
        let set1: Set<Character> = ["a", "b", "c", "d"]
        let set2: Set<Character> = ["b", "d", "e", "f"]
        
        let difference = set1.subtracting(set2)
        XCTAssertEqual(difference.count, 2, "Difference should contain elements only in first set")
        XCTAssertTrue(difference.contains("a"), "Difference should contain unique elements from first set")
        XCTAssertTrue(difference.contains("c"), "Difference should contain unique elements from first set")
        XCTAssertFalse(difference.contains("b"), "Difference should not contain common elements")
    }
    
    func testSetSymmetricDifference() {
        let set1: Set<Int> = [1, 2, 3]
        let set2: Set<Int> = [2, 3, 4]
        
        let symmetricDiff = set1.symmetricDifference(set2)
        XCTAssertEqual(symmetricDiff.count, 2, "Symmetric difference should contain elements in either set but not both")
        XCTAssertTrue(symmetricDiff.contains(1), "Symmetric difference should contain elements unique to first set")
        XCTAssertTrue(symmetricDiff.contains(4), "Symmetric difference should contain elements unique to second set")
        XCTAssertFalse(symmetricDiff.contains(2), "Symmetric difference should not contain common elements")
    }
    
    func testSetSubsetSuperset() {
        let smallSet: Set<String> = ["cat", "dog"]
        let largeSet: Set<String> = ["cat", "dog", "bird", "fish"]
        
        XCTAssertTrue(smallSet.isSubset(of: largeSet), "Small set should be subset of large set")
        XCTAssertTrue(largeSet.isSuperset(of: smallSet), "Large set should be superset of small set")
        XCTAssertFalse(largeSet.isSubset(of: smallSet), "Large set should not be subset of small set")
        
        let identicalSet: Set<String> = ["cat", "dog"]
        XCTAssertTrue(smallSet.isSubset(of: identicalSet), "Set should be subset of identical set")
        XCTAssertFalse(smallSet.isStrictSubset(of: identicalSet), "Set should not be strict subset of identical set")
    }
    
    func testSetFiltering() {
        let numbers: Set<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        
        let evenNumbers = numbers.filter { $0 % 2 == 0 }
        XCTAssertEqual(evenNumbers.count, 5, "Filtering should work on sets")
        XCTAssertTrue(evenNumbers.contains(2), "Filtered set should contain correct elements")
        XCTAssertTrue(evenNumbers.contains(10), "Filtered set should contain correct elements")
        XCTAssertFalse(evenNumbers.contains(1), "Filtered set should not contain filtered out elements")
    }
} 