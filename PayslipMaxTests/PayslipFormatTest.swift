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
        let format = PayslipFormat.military
        
        switch format {
        case .military:
            XCTAssert(true, "Military case should be matched")
        case .pcda:
            XCTFail("Should not match PCDA case")
        case .standard:
            XCTFail("Should not match Standard case")
        case .corporate:
            XCTFail("Should not match Corporate case")
        case .psu:
            XCTFail("Should not match PSU case")
        case .unknown:
            XCTFail("Should not match Unknown case")
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