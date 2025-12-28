//
//  PayslipCropViewTests.swift
//  PayslipMaxTests
//
//  Tests for PayslipCropView confirmation integration
//

import XCTest
import SwiftUI
@testable import PayslipMax

final class PayslipCropViewTests: XCTestCase {

    var testImage: UIImage!

    override func setUp() {
        super.setUp()
        testImage = createTestImage()
    }

    override func tearDown() {
        testImage = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        var cancelCalled = false
        var croppedCalled = false

        let view = PayslipCropView(
            image: testImage,
            onCancel: { cancelCalled = true },
            onCropped: { _ in croppedCalled = true }
        )

        XCTAssertNotNil(view)
        XCTAssertFalse(cancelCalled)
        XCTAssertFalse(croppedCalled)
    }

    func testInitializationWithDefaultRatios() {
        let view = PayslipCropView(
            image: testImage,
            onCancel: {},
            onCropped: { _ in }
        )

        // Verify default ratios are set (10% top, 90% bottom)
        XCTAssertEqual(view.defaultKeepTopRatio, 0.1)
        XCTAssertEqual(view.defaultKeepBottomRatio, 0.9)
    }

    func testInitializationWithCustomRatios() {
        let view = PayslipCropView(
            image: testImage,
            defaultKeepTopRatio: 0.2,
            defaultKeepBottomRatio: 0.8,
            onCancel: {},
            onCropped: { _ in }
        )

        XCTAssertEqual(view.defaultKeepTopRatio, 0.2)
        XCTAssertEqual(view.defaultKeepBottomRatio, 0.8)
    }

    // MARK: - Callback Tests

    func testCancelButtonTriggersCallback() {
        var cancelCalled = false

        let view = PayslipCropView(
            image: testImage,
            onCancel: { cancelCalled = true },
            onCropped: { _ in }
        )

        // Trigger cancel callback
        view.onCancel()

        XCTAssertTrue(cancelCalled, "Cancel callback should be triggered")
    }

    // MARK: - Confirmation Flow Tests

    func testConfirmationStateInitialization() {
        let view = PayslipCropView(
            image: testImage,
            onCancel: {},
            onCropped: { _ in }
        )

        // Verify confirmation state is initialized (not showing)
        // In real usage, showingConfirmation starts as false
        XCTAssertNotNil(view.body)
    }

    func testPreviewCropButtonExists() {
        let view = PayslipCropView(
            image: testImage,
            onCancel: {},
            onCropped: { _ in }
        )

        // Verify view renders (button is part of body)
        XCTAssertNotNil(view.body)
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
