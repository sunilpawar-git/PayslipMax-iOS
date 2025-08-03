import XCTest
@testable import PayslipMax

/// Test for PayslipFormat enum functionality
final class PayslipFormatTest: XCTestCase {
    
    func testPayslipFormatCases() {
        // Test that all enum cases exist and are accessible
        let formats: [PayslipFormat] = [.military, .pcda, .standard, .corporate, .psu, .unknown]
        
        XCTAssertEqual(formats.count, 6)
        XCTAssertTrue(formats.contains(.military))
        XCTAssertTrue(formats.contains(.pcda))
        XCTAssertTrue(formats.contains(.standard))
        XCTAssertTrue(formats.contains(.corporate))
        XCTAssertTrue(formats.contains(.psu))
        XCTAssertTrue(formats.contains(.unknown))
    }
    
    func testPayslipFormatEquality() {
        XCTAssertEqual(PayslipFormat.military, PayslipFormat.military)
        XCTAssertEqual(PayslipFormat.pcda, PayslipFormat.pcda)
        XCTAssertEqual(PayslipFormat.standard, PayslipFormat.standard)
        XCTAssertNotEqual(PayslipFormat.military, PayslipFormat.pcda)
        XCTAssertNotEqual(PayslipFormat.corporate, PayslipFormat.unknown)
        XCTAssertNotEqual(PayslipFormat.psu, PayslipFormat.standard)
    }
    
    func testPayslipFormatSwitching() {
        let formats = [PayslipFormat.military, PayslipFormat.pcda, PayslipFormat.standard]
        
        for format in formats {
            switch format {
            case .military:
                XCTAssertEqual(format, .military, "Military case should be matched")
            case .pcda:
                XCTAssertEqual(format, .pcda, "PCDA case should be matched")
            case .standard:
                XCTAssertEqual(format, .standard, "Standard case should be matched")
            case .corporate:
                XCTAssertEqual(format, .corporate, "Corporate case should be matched")
            case .psu:
                XCTAssertEqual(format, .psu, "PSU case should be matched")
            case .unknown:
                XCTAssertEqual(format, .unknown, "Unknown case should be matched")
            }
        }
    }
    
    func testFormatDetectionScenario() {
        // Test typical usage pattern in format detection
        func detectFormat(text: String) -> PayslipFormat {
            if text.contains("MILITARY") || text.contains("RANK") {
                return .military
            } else if text.contains("PCDA") || text.contains("PENSION") {
                return .pcda
            } else if text.contains("STANDARD") || text.contains("BASIC") {
                return .standard
            } else if text.contains("CORPORATE") || text.contains("COMPANY") {
                return .corporate
            } else if text.contains("PSU") || text.contains("PUBLIC SECTOR") {
                return .psu
            } else {
                return .unknown
            }
        }
        
        XCTAssertEqual(detectFormat(text: "MILITARY PAYSLIP"), .military)
        XCTAssertEqual(detectFormat(text: "PCDA PAYMENT"), .pcda)
        XCTAssertEqual(detectFormat(text: "STANDARD PAYSLIP"), .standard)
        XCTAssertEqual(detectFormat(text: "CORPORATE SALARY"), .corporate)
        XCTAssertEqual(detectFormat(text: "PSU PAYMENT"), .psu)
        XCTAssertEqual(detectFormat(text: "Random text"), .unknown)
    }
}