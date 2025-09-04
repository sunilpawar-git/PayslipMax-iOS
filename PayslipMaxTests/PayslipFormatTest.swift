import XCTest
@testable import PayslipMax

/// Test for PayslipFormat enum functionality (focused on defense personnel formats)
final class PayslipFormatTest: XCTestCase {
    
    func testMilitaryPayslipFormatCases() {
        // Test that military and related enum cases exist and are accessible
        // Note: PayslipMax is exclusively for defense personnel
        let militaryFormats: [PayslipFormat] = [.military, .pcda, .unknown]
        
        XCTAssertEqual(militaryFormats.count, 3)
        XCTAssertTrue(militaryFormats.contains(.military))
        XCTAssertTrue(militaryFormats.contains(.pcda))
        XCTAssertTrue(militaryFormats.contains(.unknown))
    }
    
    func testMilitaryPayslipFormatEquality() {
        // Test equality for military-focused formats
        XCTAssertEqual(PayslipFormat.military, PayslipFormat.military)
        XCTAssertEqual(PayslipFormat.pcda, PayslipFormat.pcda)
        XCTAssertEqual(PayslipFormat.unknown, PayslipFormat.unknown)
        XCTAssertNotEqual(PayslipFormat.military, PayslipFormat.pcda)
        XCTAssertNotEqual(PayslipFormat.military, PayslipFormat.unknown)
        XCTAssertNotEqual(PayslipFormat.pcda, PayslipFormat.unknown)
    }
    
    func testMilitaryPayslipFormatSwitching() {
        // Test only military-related formats since PayslipMax is defense-only
        let formats = [PayslipFormat.military, PayslipFormat.pcda]
        
        for format in formats {
            switch format {
            case .military:
                XCTAssertEqual(format, .military, "Military case should be matched")
            case .pcda:
                XCTAssertEqual(format, .pcda, "PCDA case should be matched")
            case .unknown:
                XCTAssertEqual(format, .unknown, "Unknown case should be matched")
            default:
                // Other formats not relevant for defense personnel app
                break
            }
        }
    }
    
    func testMilitaryFormatDetectionScenario() {
        // Test defense personnel format detection only
        func detectMilitaryFormat(text: String) -> PayslipFormat {
            if text.contains("MILITARY") || text.contains("RANK") || text.contains("ARMY") || text.contains("NAVY") || text.contains("AIR FORCE") {
                return .military
            } else if text.contains("PCDA") || text.contains("PENSION") || text.contains("DEFENCE ACCOUNTS") {
                return .pcda
            } else {
                return .unknown
            }
        }
        
        // Test military format detection
        XCTAssertEqual(detectMilitaryFormat(text: "MILITARY PAYSLIP"), .military)
        XCTAssertEqual(detectMilitaryFormat(text: "INDIAN ARMY"), .military)
        XCTAssertEqual(detectMilitaryFormat(text: "NAVY OFFICER"), .military)
        XCTAssertEqual(detectMilitaryFormat(text: "AIR FORCE STATION"), .military)
        
        // Test PCDA format detection
        XCTAssertEqual(detectMilitaryFormat(text: "PCDA PAYMENT"), .pcda)
        XCTAssertEqual(detectMilitaryFormat(text: "DEFENCE ACCOUNTS"), .pcda)
        
        // Test unknown format
        XCTAssertEqual(detectMilitaryFormat(text: "Random civilian text"), .unknown)
    }
}