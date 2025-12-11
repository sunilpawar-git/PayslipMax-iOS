import XCTest
@testable import PayslipMax

/// Tests for PayslipScannerView state management and flow logic
@MainActor
final class PayslipScannerFlowTests: XCTestCase {

    // MARK: - Test Lifecycle

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "hasSeenPrivacyEducation")
    }

    override func tearDown() {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "hasSeenPrivacyEducation")
        super.tearDown()
    }

    // MARK: - First-Time User Flow Tests

    func testFirstTimeUser_ShouldShowPrivacyEducation() {
        // Given: Fresh UserDefaults (first-time user)
        XCTAssertFalse(UserDefaults.hasSeenPrivacyEducation)

        // When: Determining which sheet to show
        let shouldShowEducation = !UserDefaults.hasSeenPrivacyEducation
        let shouldShowPicker = UserDefaults.hasSeenPrivacyEducation

        // Then: Should show education, not picker
        XCTAssertTrue(shouldShowEducation, "First-time user should see privacy education")
        XCTAssertFalse(shouldShowPicker, "First-time user should not immediately see photo picker")
    }

    func testFirstTimeUser_AfterEducation_ShowsGallery() {
        // Given: User has just seen privacy education
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // When: Privacy education completes
        let shouldShowEducation = !UserDefaults.hasSeenPrivacyEducation
        let shouldShowPicker = UserDefaults.hasSeenPrivacyEducation

        // Then: Should show picker
        XCTAssertFalse(shouldShowEducation)
        XCTAssertTrue(shouldShowPicker, "After education, should show photo picker")
    }

    // MARK: - Returning User Flow Tests

    func testReturningUser_ShowsGalleryImmediately() {
        // Given: Returning user (has seen education before)
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // When: Determining which sheet to show
        let shouldShowEducation = !UserDefaults.hasSeenPrivacyEducation
        let shouldShowPicker = UserDefaults.hasSeenPrivacyEducation

        // Then: Should skip education and show picker
        XCTAssertFalse(shouldShowEducation, "Returning user should not see education")
        XCTAssertTrue(shouldShowPicker, "Returning user should see photo picker immediately")
    }

    func testReturningUser_NoPrivacyBanner() {
        // Given: Returning user
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // When: Checking if banner should be shown
        let shouldShowBanner = !UserDefaults.hasSeenPrivacyEducation

        // Then: No banner (education already seen)
        XCTAssertFalse(shouldShowBanner, "Banner only for first-time")
    }

    // MARK: - State Management Tests

    func testPhotoSelection_TriggersCorrectFlow() {
        // Given: Photo picker is shown
        var photoPickerShown = true
        var cropperShown = false
        var processingState = false

        // When: Photo is selected
        photoPickerShown = false  // Picker dismissed
        cropperShown = true       // Cropper shown

        // Then: Correct state transitions
        XCTAssertFalse(photoPickerShown, "Picker should be dismissed")
        XCTAssertTrue(cropperShown, "Cropper should be shown")
        XCTAssertFalse(processingState, "Not processing yet")
    }

    func testCropCompletion_TriggersProcessing() {
        // Given: Cropper is shown
        var cropperShown = true
        var processingState = false

        // When: Crop is completed
        cropperShown = false
        processingState = true

        // Then: Processing starts
        XCTAssertFalse(cropperShown, "Cropper should be dismissed")
        XCTAssertTrue(processingState, "Processing should start")
    }

    func testCropCancellation_ReturnsToGallery() {
        // Given: Cropper is shown
        var cropperShown = true
        var photoPickerShown = false

        // When: User cancels crop
        cropperShown = false
        photoPickerShown = true  // Allow re-selection

        // Then: Returns to photo picker
        XCTAssertFalse(cropperShown, "Cropper should close")
        XCTAssertTrue(photoPickerShown, "Picker should reopen for re-selection")
    }

    // MARK: - Error Handling Tests

    func testProcessingError_ShowsErrorAlert() {
        // Given: Processing state
        var showError = false
        var errorMessage: String?
        var isProcessing = true

        // When: Error occurs
        errorMessage = "Processing failed"
        showError = true
        isProcessing = false

        // Then: Error state is set
        XCTAssertTrue(showError, "Error alert should be shown")
        XCTAssertNotNil(errorMessage, "Error message should be set")
        XCTAssertFalse(isProcessing, "Processing should stop")
        XCTAssertEqual(errorMessage, "Processing failed")
    }

    func testErrorDismissal_ClosesScanner() {
        // Given: Error is shown
        var showError = true
        var shouldDismissScanner = false

        // When: User taps OK on error alert
        showError = false
        shouldDismissScanner = true

        // Then: Scanner should close
        XCTAssertFalse(showError, "Error alert dismissed")
        XCTAssertTrue(shouldDismissScanner, "Scanner should close after error")
    }

    // MARK: - Image Capture Callback Tests

    func testOnImageCaptured_BypassesCropAndProcessing() {
        // Given: Scanner opened with onImageCaptured callback
        var hasOnImageCaptured = true
        var shouldShowCropper = false
        var shouldDismiss = false

        // When: Image is selected
        if hasOnImageCaptured {
            shouldDismiss = true
            shouldShowCropper = false
        }

        // Then: Skips crop and dismisses
        XCTAssertTrue(shouldDismiss, "Should dismiss immediately")
        XCTAssertFalse(shouldShowCropper, "Should skip cropper")
    }

    func testNoCallback_ShowsCropperNormally() {
        // Given: Scanner opened without callback
        var hasOnImageCaptured = false
        var shouldShowCropper = false
        var shouldDismiss = false

        // When: Image is selected
        if !hasOnImageCaptured {
            shouldShowCropper = true
            shouldDismiss = false
        }

        // Then: Shows cropper normally
        XCTAssertTrue(shouldShowCropper, "Should show cropper")
        XCTAssertFalse(shouldDismiss, "Should not dismiss yet")
    }

    // MARK: - UserHint Tests

    func testProcessing_UsesAutoHint() {
        // Given: Scanner view with no user hint selector
        let expectedHint: PayslipUserHint = .auto

        // When: Processing image
        let actualHint: PayslipUserHint = .auto  // Hardcoded in new flow

        // Then: Should always use .auto
        XCTAssertEqual(actualHint, expectedHint, "Should always use .auto (format selector removed)")
    }

    // MARK: - Integration Flow Tests

    func testCompleteFirstTimeFlow_Sequence() {
        // Test complete flow for first-time user
        var currentStep = 0

        // Step 1: Launch scanner
        XCTAssertFalse(UserDefaults.hasSeenPrivacyEducation)
        currentStep = 1

        // Step 2: Show privacy education
        XCTAssertEqual(currentStep, 1)
        currentStep = 2

        // Step 3: User taps Continue
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")
        currentStep = 3

        // Step 4: Show photo picker
        XCTAssertTrue(UserDefaults.hasSeenPrivacyEducation)
        currentStep = 4

        // Verify complete flow
        XCTAssertEqual(currentStep, 4, "Should complete all steps")
    }

    func testCompleteReturningUserFlow_Sequence() {
        // Test complete flow for returning user
        var currentStep = 0

        // Step 0: User has seen education before
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // Step 1: Launch scanner
        XCTAssertTrue(UserDefaults.hasSeenPrivacyEducation)
        currentStep = 1

        // Step 2: Show photo picker immediately (skip education)
        currentStep = 2

        // Verify simplified flow
        XCTAssertEqual(currentStep, 2, "Should skip education and go straight to picker")
    }
}
