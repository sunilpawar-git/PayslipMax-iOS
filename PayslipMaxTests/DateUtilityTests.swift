import XCTest
import Foundation
@testable import PayslipMax

final class DateUtilityTests: XCTestCase {
    
    func testBasicDateOperations() {
        let calendar = Calendar.current
        let now = Date()
        
        // Test date creation
        let components = DateComponents(year: 2024, month: 1, day: 15)
        let testDate = calendar.date(from: components)
        XCTAssertNotNil(testDate, "Date creation should work")
        
        // Test date comparison
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        XCTAssertTrue(tomorrow > now, "Date comparison should work")
        
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        XCTAssertTrue(yesterday < now, "Date comparison should work")
    }
    
    func testDateFormatting() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let components = DateComponents(year: 2024, month: 6, day: 15)
        let testDate = Calendar.current.date(from: components)!
        
        let formatted = formatter.string(from: testDate)
        XCTAssertEqual(formatted, "2024-06-15", "Date formatting should work")
        
        // Test different format
        formatter.dateFormat = "dd/MM/yyyy"
        let alternateFormat = formatter.string(from: testDate)
        XCTAssertEqual(alternateFormat, "15/06/2024", "Alternate date formatting should work")
    }
    
    func testDateArithmetic() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        
        // Add days
        let futureDate = calendar.date(byAdding: .day, value: 30, to: startDate)!
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: futureDate).day!
        XCTAssertEqual(daysDifference, 30, "Date arithmetic should work")
        
        // Add months
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate)!
        let monthsDifference = calendar.dateComponents([.month], from: startDate, to: nextMonth).month!
        XCTAssertEqual(monthsDifference, 1, "Month arithmetic should work")
    }
    
    func testDateComponents() {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        
        let year = calendar.component(.year, from: testDate)
        XCTAssertEqual(year, 2024, "Year component should be correct")
        
        let month = calendar.component(.month, from: testDate)
        XCTAssertEqual(month, 6, "Month component should be correct")
        
        let day = calendar.component(.day, from: testDate)
        XCTAssertEqual(day, 15, "Day component should be correct")
    }
    
    func testDateValidation() {
        let calendar = Calendar.current
        
        // Test valid date
        let validComponents = DateComponents(year: 2024, month: 2, day: 29) // Leap year
        let validDate = calendar.date(from: validComponents)
        XCTAssertNotNil(validDate, "Valid leap year date should be created")
        
        // Test weekend detection
        let sundayComponents = DateComponents(year: 2024, month: 6, day: 16) // Sunday
        let sunday = calendar.date(from: sundayComponents)!
        let weekday = calendar.component(.weekday, from: sunday)
        XCTAssertEqual(weekday, 1, "Sunday should be weekday 1")
    }
    
    func testTimeIntervals() {
        let startTime = Date()
        let endTime = Date(timeInterval: 3600, since: startTime) // 1 hour later
        
        let interval = endTime.timeIntervalSince(startTime)
        XCTAssertEqual(interval, 3600, accuracy: 0.1, "Time interval should be correct")
        
        let oneHour: TimeInterval = 60 * 60
        XCTAssertEqual(oneHour, 3600, "Time interval calculation should work")
    }
} 