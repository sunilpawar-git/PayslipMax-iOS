import XCTest
import SwiftUI
@testable import PayslipMax

final class XRayShieldIndicatorTests: XCTestCase {

    func testEnabledStateUsesGreenAndEnabledLabel() {
        let config = XRayShieldIndicator(isEnabled: true, onTap: {}).debugConfig()
        XCTAssertEqual(config.color, FintechColors.successGreen)
        XCTAssertEqual(config.label, "X-Ray feature enabled")
    }

    func testDisabledStateUsesRedAndDisabledLabel() {
        let config = XRayShieldIndicator(isEnabled: false, onTap: {}).debugConfig()
        XCTAssertEqual(config.color, FintechColors.dangerRed)
        XCTAssertEqual(config.label, "X-Ray feature disabled")
    }
}

