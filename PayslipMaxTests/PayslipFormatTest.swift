import XCTest
@testable import PayslipMax

/// Test for PayslipFormat enum functionality (unified defense personnel format)
final class PayslipFormatTest: XCTestCase {
    
    func testDefensePayslipFormatCases() {
        // Test that unified defense format and unknown cases exist and are accessible
        // Note: PayslipMax is exclusively for defense personnel with unified processing
        let defenseFormats: [PayslipFormat] = [.defense, .unknown]
        
        XCTAssertEqual(defenseFormats.count, 2)
        XCTAssertTrue(defenseFormats.contains(.defense))
        XCTAssertTrue(defenseFormats.contains(.unknown))
    }
    
    func testDefensePayslipFormatEquality() {
        // Test equality for unified defense format
        XCTAssertEqual(PayslipFormat.defense, PayslipFormat.defense)
        XCTAssertEqual(PayslipFormat.unknown, PayslipFormat.unknown)
        XCTAssertNotEqual(PayslipFormat.defense, PayslipFormat.unknown)
    }
    
    func testDefensePayslipFormatSwitching() {
        // Test unified defense format since PayslipMax uses unified processing
        let formats = [PayslipFormat.defense, PayslipFormat.unknown]
        
        for format in formats {
            switch format {
            case .defense:
                XCTAssertEqual(format, .defense, "Defense case should be matched")
            case .unknown:
                XCTAssertEqual(format, .unknown, "Unknown case should be matched")
            }
        }
    }
    
    func testUnifiedDefenseFormatDetectionScenario() {
        // Test unified defense personnel format detection
        func detectDefenseFormat(text: String) -> PayslipFormat {
            let defenseKeywords = [
                "MILITARY", "ARMY", "NAVY", "AIR FORCE", "DEFENCE",
                "PCDA", "PRINCIPAL CONTROLLER", "DEFENCE ACCOUNTS",
                "SERVICE NO", "RANK", "DSOP", "AGIF", "MSP"
            ]
            
            if defenseKeywords.contains(where: { text.uppercased().contains($0) }) {
                return .defense
            } else {
                return .unknown
            }
        }
        
        // Test unified defense format detection for all service branches
        XCTAssertEqual(detectDefenseFormat(text: "MILITARY PAYSLIP"), .defense)
        XCTAssertEqual(detectDefenseFormat(text: "INDIAN ARMY"), .defense)
        XCTAssertEqual(detectDefenseFormat(text: "NAVY OFFICER"), .defense)
        XCTAssertEqual(detectDefenseFormat(text: "AIR FORCE STATION"), .defense)
        
        // Test PCDA keywords also map to unified defense format
        XCTAssertEqual(detectDefenseFormat(text: "PCDA PAYMENT"), .defense)
        XCTAssertEqual(detectDefenseFormat(text: "DEFENCE ACCOUNTS"), .defense)
        XCTAssertEqual(detectDefenseFormat(text: "PRINCIPAL CONTROLLER"), .defense)
        
        // Test defense-specific financial keywords
        XCTAssertEqual(detectDefenseFormat(text: "DSOP FUND"), .defense)
        XCTAssertEqual(detectDefenseFormat(text: "AGIF CONTRIBUTION"), .defense)
        XCTAssertEqual(detectDefenseFormat(text: "MSP ALLOWANCE"), .defense)
        
        // Test unknown format
        XCTAssertEqual(detectDefenseFormat(text: "Random civilian text"), .unknown)
    }
}