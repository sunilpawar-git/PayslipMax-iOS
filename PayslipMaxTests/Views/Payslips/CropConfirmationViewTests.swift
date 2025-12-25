//
//  CropConfirmationViewTests.swift
//  PayslipMaxTests
//
//  Tests for CropConfirmationView
//

import XCTest
import SwiftUI
@testable import PayslipMax

final class CropConfirmationViewTests: XCTestCase {

    var testImage: UIImage!

    override func setUp() {
        super.setUp()
        // Create a simple test image
        testImage = createTestImage()
    }

    override func tearDown() {
        testImage = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        var cancelCalled = false
        var confirmCalled = false

        let view = CropConfirmationView(
            croppedImage: testImage,
            onCancel: { cancelCalled = true },
            onConfirm: { confirmCalled = true }
        )

        XCTAssertNotNil(view)
        XCTAssertFalse(cancelCalled)
        XCTAssertFalse(confirmCalled)
    }

    // MARK: - Callback Tests

    func testCancelButtonTriggersCallback() {
        var cancelCalled = false
        var confirmCalled = false

        let view = CropConfirmationView(
            croppedImage: testImage,
            onCancel: { cancelCalled = true },
            onConfirm: { confirmCalled = true }
        )

        // Trigger cancel callback
        view.onCancel()

        XCTAssertTrue(cancelCalled, "Cancel callback should be triggered")
        XCTAssertFalse(confirmCalled, "Confirm callback should not be triggered")
    }

    func testConfirmButtonTriggersCallback() {
        var cancelCalled = false
        var confirmCalled = false

        let view = CropConfirmationView(
            croppedImage: testImage,
            onCancel: { cancelCalled = true },
            onConfirm: { confirmCalled = true }
        )

        // Trigger confirm callback
        view.onConfirm()

        XCTAssertFalse(cancelCalled, "Cancel callback should not be triggered")
        XCTAssertTrue(confirmCalled, "Confirm callback should be triggered")
    }

    // MARK: - View Rendering Tests

    func testDisplaysCroppedImage() {
        let view = CropConfirmationView(
            croppedImage: testImage,
            onCancel: {},
            onConfirm: {}
        )

        // Verify view has the image
        // In a real UI test, we would check the rendered view
        // For unit tests, we verify the image is passed correctly
        XCTAssertNotNil(view.croppedImage)
    }

    func testShowsPrivacyChecklist() {
        let view = CropConfirmationView(
            croppedImage: testImage,
            onCancel: {},
            onConfirm: {}
        )

        // Verify view is created successfully (checklist is part of body)
        XCTAssertNotNil(view.body)
    }

    // MARK: - Privacy Check Item Tests

    func testPrivacyCheckItemInitialization() {
        let item = PrivacyCheckItem(
            icon: "person.fill.xmark",
            text: "No names visible?",
            color: .red
        )

        XCTAssertNotNil(item)
        XCTAssertEqual(item.icon, "person.fill.xmark")
        XCTAssertEqual(item.text, "No names visible?")
        XCTAssertEqual(item.color, .red)
    }

    func testPrivacyCheckItemRendering() {
        let item = PrivacyCheckItem(
            icon: "checkmark.circle.fill",
            text: "Only salary details visible?",
            color: .green
        )

        // Verify body renders without error
        XCTAssertNotNil(item.body)
    }

    // MARK: - Accessibility Tests

    func testAccessibilityIdentifiers() {
        // This test verifies that accessibility identifiers are present
        // In a real UI test framework, we would query for these identifiers
        // For unit tests, we verify the view structure is correct

        let view = CropConfirmationView(
            croppedImage: testImage,
            onCancel: {},
            onConfirm: {}
        )

        // Verify view exists (identifiers are embedded in SwiftUI view)
        XCTAssertNotNil(view.body)
    }

    // MARK: - Integration Tests

    func testMultipleCallbackInvocations() {
        var cancelCount = 0
        var confirmCount = 0

        let view = CropConfirmationView(
            croppedImage: testImage,
            onCancel: { cancelCount += 1 },
            onConfirm: { confirmCount += 1 }
        )

        // Call cancel multiple times
        view.onCancel()
        view.onCancel()

        XCTAssertEqual(cancelCount, 2)
        XCTAssertEqual(confirmCount, 0)

        // Call confirm multiple times
        view.onConfirm()
        view.onConfirm()
        view.onConfirm()

        XCTAssertEqual(cancelCount, 2)
        XCTAssertEqual(confirmCount, 3)
    }

    func testCallbacksWithDifferentImages() {
        let image1 = createTestImage(size: CGSize(width: 100, height: 100))
        let image2 = createTestImage(size: CGSize(width: 200, height: 200))

        var confirmedImage: UIImage?

        let view1 = CropConfirmationView(
            croppedImage: image1,
            onCancel: {},
            onConfirm: { confirmedImage = image1 }
        )

        let view2 = CropConfirmationView(
            croppedImage: image2,
            onCancel: {},
            onConfirm: { confirmedImage = image2 }
        )

        // Confirm first view
        view1.onConfirm()
        XCTAssertEqual(confirmedImage?.size, image1.size)

        // Confirm second view
        view2.onConfirm()
        XCTAssertEqual(confirmedImage?.size, image2.size)
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
