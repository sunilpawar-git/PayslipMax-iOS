import XCTest
@testable import PayslipMax

final class StringUtilityTests: XCTestCase {
    
    func testBasicStringOperations() {
        let firstName = "John"
        let lastName = "Doe"
        let fullName = firstName + " " + lastName
        XCTAssertEqual(fullName, "John Doe", "String concatenation should work")
        
        let text = "Hello World"
        XCTAssertEqual(text.count, 11, "String length should be correct")
        
        let upperText = text.uppercased()
        XCTAssertEqual(upperText, "HELLO WORLD", "String uppercase should work")
    }
    
    func testStringValidation() {
        let emptyString = ""
        XCTAssertTrue(emptyString.isEmpty, "Empty string validation should work")
        
        let nonEmptyString = "Test"
        XCTAssertFalse(nonEmptyString.isEmpty, "Non-empty string validation should work")
        
        let whitespaceString = "   "
        let trimmed = whitespaceString.trimmingCharacters(in: .whitespaces)
        XCTAssertTrue(trimmed.isEmpty, "Whitespace trimming should work")
    }
    
    func testStringContains() {
        let text = "The quick brown fox"
        XCTAssertTrue(text.contains("quick"), "String contains should work")
        XCTAssertFalse(text.contains("slow"), "String contains should work for non-existing")
        
        let caseInsensitive = text.lowercased().contains("QUICK".lowercased())
        XCTAssertTrue(caseInsensitive, "Case insensitive contains should work")
    }
    
    func testStringReplacement() {
        let original = "Hello World"
        let replaced = original.replacingOccurrences(of: "World", with: "Swift")
        XCTAssertEqual(replaced, "Hello Swift", "String replacement should work")
        
        let multipleReplace = "test test test".replacingOccurrences(of: "test", with: "demo")
        XCTAssertEqual(multipleReplace, "demo demo demo", "Multiple replacements should work")
    }
    
    func testStringPrefix() {
        let text = "PayslipMax"
        XCTAssertTrue(text.hasPrefix("Pay"), "String prefix check should work")
        XCTAssertTrue(text.hasSuffix("Max"), "String suffix check should work")
        
        let prefix = String(text.prefix(3))
        XCTAssertEqual(prefix, "Pay", "String prefix extraction should work")
    }
} 