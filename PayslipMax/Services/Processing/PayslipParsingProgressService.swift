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
    }

    // MARK: - Private Methods

    private func performParsing(
        image: UIImage,
        processor: ImageImportProcessor
    ) async {
        do {
            // Step 1: Preparing
            state = .preparing
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3s for visual feedback

            // Step 2: Extracting (LLM Pass 1)
            state = .extracting

            // Process the image (this will trigger LLM vision parsing)
            let result = await processor.processCroppedImageLLMOnly(image)

            switch result {
            case .success:
                // Step 3: Validating (sanity checks happen inside parser)
                state = .validating
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

                // Step 4: Saving
                state = .saving
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2s

                // Step 5: Completed
                // Note: We don't have access to the PayslipItem here,
                // so we'll use a placeholder. The actual item is saved by the processor.
                state = .completed(PayslipItem.placeholder())
                hasNewPayslip = true

                // Auto-reset after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                if case .completed = state {
                    state = .idle
                }

            case .failure(let error):
                state = .failed(error.localizedDescription)

                // Auto-reset after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                if case .failed = state {
                    state = .idle
                }
            }

        } catch is CancellationError {
            // Task was cancelled
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

// MARK: - PayslipItem Extension

private extension PayslipItem {
    static func placeholder() -> PayslipItem {
        PayslipItem(
            month: "",
            year: 0,
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            earnings: [:],
            deductions: [:],
            source: ""
        )
    }
}
