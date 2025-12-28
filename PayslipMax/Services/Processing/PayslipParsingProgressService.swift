//
//  PayslipParsingProgressService.swift
//  PayslipMax
//
//  Manages async payslip parsing with progress tracking
//

import Foundation
import UIKit
import Combine

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
    func startParsing(image: UIImage, processor: ImageImportProcessor) {
        currentTask?.cancel()
        state = .preparing
        hasNewPayslip = false

        currentTask = Task { @MainActor in
            await performParsing(image: image, processor: processor)
        }
    }

    /// Starts async parsing with both original and cropped images
    func startParsing(
        originalImage: UIImage,
        croppedImage: UIImage,
        imageIdentifier: UUID?,
        processor: ImageImportProcessor
    ) {
        currentTask?.cancel()
        state = .preparing
        hasNewPayslip = false

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
        state = .preparing
        hasNewPayslip = false

        currentTask = Task { @MainActor in
            await callback()
        }
    }

    // MARK: - Private Methods

    private func performParsing(image: UIImage, processor: ImageImportProcessor) async {
        retryCallback = { [weak self] in
            await self?.performParsing(image: image, processor: processor)
        }

        do {
            state = .preparing
            state = .extracting
            let result = await processor.processCroppedImageLLMOnly(image)

            switch result {
            case .success(let payslip):
                state = .completed(payslip)
                hasNewPayslip = true
                retryCallback = nil

                try await Task.sleep(nanoseconds: 2_000_000_000)
                if case .completed = state {
                    state = .idle
                }

            case .failure(let error):
                state = .failed(error.localizedDescription)

                try await Task.sleep(nanoseconds: 5_000_000_000)
                if case .failed = state {
                    state = .idle
                    retryCallback = nil
                }
            }

        } catch is CancellationError {
            state = .idle
            retryCallback = nil
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func performParsingWithBothImages(
        originalImage: UIImage,
        croppedImage: UIImage,
        imageIdentifier: UUID?,
        processor: ImageImportProcessor
    ) async {
        retryCallback = { [weak self] in
            await self?.performParsingWithBothImages(
                originalImage: originalImage,
                croppedImage: croppedImage,
                imageIdentifier: imageIdentifier,
                processor: processor
            )
        }

        do {
            state = .preparing
            state = .extracting

            let result = await processor.processBothImages(
                original: originalImage,
                cropped: croppedImage,
                identifier: imageIdentifier
            )

            switch result {
            case .success(let payslip):
                state = .completed(payslip)
                hasNewPayslip = true
                retryCallback = nil

                try await Task.sleep(nanoseconds: 2_000_000_000)
                if case .completed = state {
                    state = .idle
                }

            case .failure(let error):
                state = .failed(error.localizedDescription)

                try await Task.sleep(nanoseconds: 5_000_000_000)
                if case .failed = state {
                    state = .idle
                    retryCallback = nil
                }
            }

        } catch is CancellationError {
            state = .idle
            retryCallback = nil
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
