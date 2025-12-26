//
//  PayslipParsingProgressService.swift
//  PayslipMax
//
//  Manages async payslip parsing with progress tracking
//

import Foundation
import UIKit
import Combine

/// Progress state for payslip parsing operations
enum ParsingProgressState: Equatable {
    case idle
    case preparing                          // Setting up for parsing
    case extracting                         // First LLM pass or OCR
    case validating                         // Sanity checks
    case verifying                          // Second LLM pass (if needed)
    case saving                             // Saving to database
    case completed(PayslipItem)             // Done with result
    case failed(String)                     // Error occurred

    var isActive: Bool {
        switch self {
        case .idle, .completed, .failed:
            return false
        default:
            return true
        }
    }

    var progressMessage: String {
        switch self {
        case .idle:
            return ""
        case .preparing:
            return "Preparing payslip..."
        case .extracting:
            return "Analyzing payslip... 🔍"
        case .validating:
            return "Validating data..."
        case .verifying:
            return "Verifying accuracy..."
        case .saving:
            return "Saving payslip..."
        case .completed:
            return "Complete ✓"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }

    var progressPercent: Double {
        switch self {
        case .idle:
            return 0.0
        case .preparing:
            return 0.1
        case .extracting:
            return 0.3
        case .validating:
            return 0.6
        case .verifying:
            return 0.8
        case .saving:
            return 0.95
        case .completed:
            return 1.0
        case .failed:
            return 0.0
        }
    }
}

/// Service for managing async payslip parsing with progress updates
@MainActor
final class PayslipParsingProgressService: ObservableObject {
    // MARK: - Singleton

    static let shared = PayslipParsingProgressService()

    // MARK: - Published Properties

    @Published private(set) var state: ParsingProgressState = .idle
    @Published private(set) var hasNewPayslip: Bool = false  // For badge indicator

    // MARK: - Private Properties

    private var currentTask: Task<Void, Never>?
    private var retryCallback: (() async -> Void)?

    // Private init for singleton
    private init() {}

    // MARK: - Public API

    /// Starts async parsing with progress updates
    /// - Parameters:
    ///   - image: The cropped payslip image
    ///   - processor: The image import processor
    func startParsing(
        image: UIImage,
        processor: ImageImportProcessor
    ) {
        // Cancel any existing task
        currentTask?.cancel()

        // Reset state
        state = .preparing
        hasNewPayslip = false

        // Start async parsing
        currentTask = Task { @MainActor in
            await performParsing(image: image, processor: processor)
        }
    }

    /// Starts async parsing with both original and cropped images
    /// - Parameters:
    ///   - originalImage: The uncropped original image (for PDF storage)
    ///   - croppedImage: The cropped image (for LLM processing)
    ///   - imageIdentifier: UUID for linking to saved image files
    ///   - processor: The image import processor
    func startParsing(
        originalImage: UIImage,
        croppedImage: UIImage,
        imageIdentifier: UUID?,
        processor: ImageImportProcessor
    ) {
        // Cancel any existing task
        currentTask?.cancel()

        // Reset state
        state = .preparing
        hasNewPayslip = false

        // Start async parsing with both images
        currentTask = Task { @MainActor in
            await performParsingWithBothImages(
                originalImage: originalImage,
                croppedImage: croppedImage,
                imageIdentifier: imageIdentifier,
                processor: processor
            )
        }
    }

    /// Clears the "new payslip" badge
    func clearNewPayslipBadge() {
        hasNewPayslip = false
    }

    /// Resets to idle state
    func reset() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
        hasNewPayslip = false
        retryCallback = nil
    }

    /// Retries the last failed parsing operation
    func retry() {
        guard let callback = retryCallback else { return }

        // Reset state and retry
        state = .preparing
        hasNewPayslip = false

        currentTask = Task { @MainActor in
            await callback()
        }
    }

    // MARK: - Private Methods

    private func performParsing(
        image: UIImage,
        processor: ImageImportProcessor
    ) async {
        // Store retry callback
        retryCallback = { [weak self] in
            await self?.performParsing(image: image, processor: processor)
        }

        do {
            // Step 1: Preparing (brief visual feedback)
            state = .preparing

            // Step 2: Extracting (LLM Pass 1)
            state = .extracting

            // Process the image (this will trigger LLM vision parsing)
            // Validation and verification happen inside the parser
            let result = await processor.processCroppedImageLLMOnly(image)

            switch result {
            case .success(let payslip):
                // Step 3: Completed with real payslip data
                state = .completed(payslip)
                hasNewPayslip = true
                retryCallback = nil  // Clear retry on success

                // Auto-reset after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                if case .completed = state {
                    state = .idle
                }

            case .failure(let error):
                state = .failed(error.localizedDescription)
                // Keep retryCallback for retry button

                // Auto-reset after 5 seconds (longer for retry)
                try await Task.sleep(nanoseconds: 5_000_000_000)
                if case .failed = state {
                    state = .idle
                    retryCallback = nil
                }
            }

        } catch is CancellationError {
            // Task was cancelled
            state = .idle
            retryCallback = nil
        } catch {
            state = .failed(error.localizedDescription)
            // Keep retryCallback for retry button
        }
    }

    /// Performs parsing with both original and cropped images
    /// - Parameters:
    ///   - originalImage: The uncropped original image (for PDF storage)
    ///   - croppedImage: The cropped image (for LLM processing)
    ///   - imageIdentifier: UUID for linking to saved image files
    ///   - processor: The image import processor
    private func performParsingWithBothImages(
        originalImage: UIImage,
        croppedImage: UIImage,
        imageIdentifier: UUID?,
        processor: ImageImportProcessor
    ) async {
        // Store retry callback
        retryCallback = { [weak self] in
            await self?.performParsingWithBothImages(
                originalImage: originalImage,
                croppedImage: croppedImage,
                imageIdentifier: imageIdentifier,
                processor: processor
            )
        }

        do {
            // Step 1: Preparing (brief visual feedback)
            state = .preparing

            // Step 2: Extracting (LLM Pass 1)
            state = .extracting

            // Process with BOTH images
            // Original image -> PDF for storage
            // Cropped image -> LLM/OCR processing
            let result = await processor.processBothImages(
                original: originalImage,
                cropped: croppedImage,
                identifier: imageIdentifier
            )

            switch result {
            case .success(let payslip):
                // PayslipItem is saved and returned by the processor
                state = .completed(payslip)
                hasNewPayslip = true
                retryCallback = nil

                // Auto-reset after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                if case .completed = state {
                    state = .idle
                }

            case .failure(let error):
                state = .failed(error.localizedDescription)
                // Keep retryCallback for retry button

                // Auto-reset after 5 seconds (longer for retry)
                try await Task.sleep(nanoseconds: 5_000_000_000)
                if case .failed = state {
                    state = .idle
                    retryCallback = nil
                }
            }

        } catch is CancellationError {
            // Task was cancelled
            state = .idle
            retryCallback = nil
        } catch {
            state = .failed(error.localizedDescription)
            // Keep retryCallback for retry button
        }
    }
}
