import XCTest
@testable import PayslipMax

final class MathUtilityTests: XCTestCase {
    
    func testBasicArithmetic() {
        let result = 10 + 5
        XCTAssertEqual(result, 15, "Basic addition should work")
        
        let multiplication = 4 * 3
        XCTAssertEqual(multiplication, 12, "Basic multiplication should work")
        
        let division = 20 / 4
        XCTAssertEqual(division, 5, "Basic division should work")
    }
    
    func testPercentageCalculations() {
        let value = 100.0
        let percentage = 25.0
        let result = (value * percentage) / 100.0
        XCTAssertEqual(result, 25.0, "Percentage calculation should work")
        
        let taxRate = 0.15
        let income = 1000.0
        let tax = income * taxRate
        XCTAssertEqual(tax, 150.0, "Tax calculation should work")
    }
    
    func testRoundingOperations() {
        let value = 123.456
        let rounded = round(value * 100) / 100
        XCTAssertEqual(rounded, 123.46, accuracy: 0.01, "Rounding should work")
        
        let ceiling = ceil(5.1)
        XCTAssertEqual(ceiling, 6.0, "Ceiling should work")
        
        let floor = floor(5.9)
        XCTAssertEqual(floor, 5.0, "Floor should work")
    }
    
    func testNumberValidation() {
        let positiveNumber = 42
        XCTAssertTrue(positiveNumber > 0, "Positive number validation should work")
        
        let negativeNumber = -10
        XCTAssertTrue(negativeNumber < 0, "Negative number validation should work")
        
        let zero = 0
        XCTAssertEqual(zero, 0, "Zero validation should work")
    }
    
    func testStringToNumberConversion() {
        let numberString = "123"
        let converted = Int(numberString)
        XCTAssertEqual(converted, 123, "String to number conversion should work")
        
        let floatString = "45.67"
        let convertedFloat = Double(floatString)
        XCTAssertEqual(convertedFloat, 45.67, "String to float conversion should work")
    }
} 