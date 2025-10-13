import XCTest
@testable import PayslipMax

/// Tests for priority-based display order in PayslipDisplayNameService
/// Ensures earnings/deductions show in correct order (not alphabetical)
final class PayslipDisplayNameServiceOrderTests: XCTestCase {
    
    var sut: PayslipDisplayNameService!
    
    override func setUp() {
        super.setUp()
        sut = PayslipDisplayNameService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Earnings Display Order Tests
    
    func testEarningsDisplayOrder_StandardFieldsShowFirst() {
        // Given: Mixed earnings with standard fields and breakdown items
        let earnings: [String: Double] = [
            "RH12": 12000.0,
            "Basic Pay": 144700.0,
            "ARRTPTL": 1705.0,
            "Military Service Pay": 15500.0,
            "Dearness Allowance": 88110.0,
            "TPTL": 13000.0
        ]
        
        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)
        
        // Then: Standard fields should show first in specific order
        XCTAssertEqual(result.count, 6, "Should have 6 earnings items")
        XCTAssertEqual(result[0].displayName, "Basic Pay", "Basic Pay should be first (Priority 1)")
        XCTAssertEqual(result[1].displayName, "Dearness Allowance", "DA should be second (Priority 2)")
        XCTAssertEqual(result[2].displayName, "Military Service Pay", "MSP should be third (Priority 3)")
        
        // Breakdown items (RH12, ARRTPTL, TPTL) should be after standard fields
        let breakdownItems = ["RH12", "Arrtptl", "TPTL"]
        XCTAssertTrue(breakdownItems.contains(result[3].displayName), "Item 4 should be a breakdown item")
        XCTAssertTrue(breakdownItems.contains(result[4].displayName), "Item 5 should be a breakdown item")
        XCTAssertTrue(breakdownItems.contains(result[5].displayName), "Item 6 should be a breakdown item")
    }
    
    func testEarningsDisplayOrder_OtherEarningsShowsLast() {
        // Given: Earnings with "Other Earnings" and breakdown items
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "Other Earnings": 5000.0,
            "RH12": 12000.0,
            "Dearness Allowance": 88110.0,
            "Military Service Pay": 15500.0
        ]
        
        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)
        
        // Then: "Other Earnings" should be last (Priority 99)
        XCTAssertEqual(result.count, 5, "Should have 5 earnings items")
        XCTAssertEqual(result.last?.displayName, "Other Earnings", "Other Earnings should be last")
        
        // Standard fields should still be first
        XCTAssertEqual(result[0].displayName, "Basic Pay")
        XCTAssertEqual(result[1].displayName, "Dearness Allowance")
        XCTAssertEqual(result[2].displayName, "Military Service Pay")
    }
    
    func testEarningsDisplayOrder_NotAlphabetical() {
        // Given: Earnings that would be in different order if alphabetical
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "ARRTPTL": 1705.0,  // Would be first alphabetically
            "Dearness Allowance": 88110.0
        ]
        
        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)
        
        // Then: Should NOT be alphabetical (Arrtptl would be first if alphabetical)
        XCTAssertNotEqual(result[0].displayName, "Arrtptl", "Should not be alphabetically sorted")
        XCTAssertEqual(result[0].displayName, "Basic Pay", "Basic Pay should be first, not Arrtptl")
    }
    
    func testEarningsDisplayOrder_OnlyStandardFields() {
        // Given: Only standard fields
        let earnings: [String: Double] = [
            "Military Service Pay": 15500.0,
            "Basic Pay": 144700.0,
            "Dearness Allowance": 88110.0
        ]
        
        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)
        
        // Then: Should be in priority order
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].displayName, "Basic Pay")
        XCTAssertEqual(result[1].displayName, "Dearness Allowance")
        XCTAssertEqual(result[2].displayName, "Military Service Pay")
    }
    
    func testEarningsDisplayOrder_OnlyBreakdownItems() {
        // Given: Only user breakdown items (no standard fields)
        let earnings: [String: Double] = [
            "RH12": 12000.0,
            "TPTL": 13000.0,
            "ARRTPTL": 1705.0
        ]
        
        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)
        
        // Then: Should have 3 items, order not guaranteed (dictionary iteration)
        XCTAssertEqual(result.count, 3)
        
        // All should be present
        let displayNames = result.map { $0.displayName }
        XCTAssertTrue(displayNames.contains("RH12"))
        XCTAssertTrue(displayNames.contains("TPTL"))
        XCTAssertTrue(displayNames.contains("Arrtptl"))
    }
    
    func testEarningsDisplayOrder_ZeroValuesFiltered() {
        // Given: Earnings with zero values
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "RH12": 0.0,  // Should be filtered
            "Dearness Allowance": 88110.0
        ]
        
        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)
        
        // Then: Should only have 2 items (zero values filtered)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].displayName, "Basic Pay")
        XCTAssertEqual(result[1].displayName, "Dearness Allowance")
    }
    
    // MARK: - Deductions Display Order Tests
    
    func testDeductionsDisplayOrder_StandardFieldsShowFirst() {
        // Given: Mixed deductions with standard fields and breakdown items
        let deductions: [String: Double] = [
            "EHCESS": 1905.0,
            "Income Tax": 47624.0,
            "DSOP": 40000.0,
            "AGIF": 12500.0,
            "Custom Deduction": 1000.0
        ]
        
        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)
        
        // Then: Standard fields should show first in specific order
        XCTAssertEqual(result.count, 5, "Should have 5 deduction items")
        XCTAssertEqual(result[0].displayName, "AGIF", "AGIF should be first (Priority 1)")
        XCTAssertEqual(result[1].displayName, "DSOP", "DSOP should be second (Priority 2)")
        XCTAssertEqual(result[2].displayName, "Income Tax", "Income Tax should be third (Priority 3)")
        
        // EHCESS and Custom Deduction should be after standard fields (positions 3-4)
        // Note: Display names may be transformed (e.g., "EHCESS" remains "EHCESS")
        let item3 = result[3].displayName
        let item4 = result[4].displayName
        
        // Verify both are NOT standard fields
        XCTAssertNotEqual(item3, "AGIF", "Item 4 should not be AGIF")
        XCTAssertNotEqual(item3, "DSOP", "Item 4 should not be DSOP")
        XCTAssertNotEqual(item3, "Income Tax", "Item 4 should not be Income Tax")
        XCTAssertNotEqual(item4, "AGIF", "Item 5 should not be AGIF")
        XCTAssertNotEqual(item4, "DSOP", "Item 5 should not be DSOP")
        XCTAssertNotEqual(item4, "Income Tax", "Item 5 should not be Income Tax")
    }
    
    func testDeductionsDisplayOrder_OtherDeductionsShowsLast() {
        // Given: Deductions with "Other Deductions"
        let deductions: [String: Double] = [
            "AGIF": 12500.0,
            "Other Deductions": 2000.0,
            "DSOP": 40000.0,
            "Income Tax": 47624.0
        ]
        
        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)
        
        // Then: "Other Deductions" should be last (Priority 99)
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result.last?.displayName, "Other Deductions", "Other Deductions should be last")
        
        // Standard fields should still be first
        XCTAssertEqual(result[0].displayName, "AGIF")
        XCTAssertEqual(result[1].displayName, "DSOP")
        XCTAssertEqual(result[2].displayName, "Income Tax")
    }
    
    func testDeductionsDisplayOrder_NotAlphabetical() {
        // Given: Deductions that would be in different order if alphabetical
        let deductions: [String: Double] = [
            "DSOP": 40000.0,
            "AGIF": 12500.0,  // Would be first alphabetically
            "Income Tax": 47624.0
        ]
        
        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)
        
        // Then: Should NOT be alphabetical (AGIF should be first by priority, not alphabet)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].displayName, "AGIF", "AGIF first by priority, not alphabet")
        XCTAssertEqual(result[1].displayName, "DSOP")
        XCTAssertEqual(result[2].displayName, "Income Tax")
    }
    
    func testDeductionsDisplayOrder_OnlyStandardFields() {
        // Given: Only standard fields
        let deductions: [String: Double] = [
            "Income Tax": 47624.0,
            "DSOP": 40000.0,
            "AGIF": 12500.0
        ]
        
        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)
        
        // Then: Should be in priority order
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].displayName, "AGIF")
        XCTAssertEqual(result[1].displayName, "DSOP")
        XCTAssertEqual(result[2].displayName, "Income Tax")
    }
    
    // MARK: - Edge Cases
    
    func testEarningsDisplayOrder_EmptyDictionary() {
        // Given: Empty earnings
        let earnings: [String: Double] = [:]
        
        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)
        
        // Then: Should return empty array
        XCTAssertTrue(result.isEmpty, "Empty earnings should return empty array")
    }
    
    func testDeductionsDisplayOrder_EmptyDictionary() {
        // Given: Empty deductions
        let deductions: [String: Double] = [:]
        
        // When: Getting display deductions
        let result = sut.getDisplayDeductions(from: deductions)
        
        // Then: Should return empty array
        XCTAssertTrue(result.isEmpty, "Empty deductions should return empty array")
    }
    
    func testEarningsDisplayOrder_AllValuesCorrect() {
        // Given: Earnings with specific values
        let earnings: [String: Double] = [
            "Basic Pay": 144700.0,
            "RH12": 12000.0,
            "Dearness Allowance": 88110.0
        ]
        
        // When: Getting display earnings
        let result = sut.getDisplayEarnings(from: earnings)
        
        // Then: Values should be preserved correctly
        XCTAssertEqual(result[0].value, 144700.0, "Basic Pay value should be preserved")
        XCTAssertEqual(result[1].value, 88110.0, "DA value should be preserved")
        XCTAssertEqual(result[2].value, 12000.0, "RH12 value should be preserved")
    }
}

