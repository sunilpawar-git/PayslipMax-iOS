//
//  ParsingProgressDelegate.swift
//  PayslipMax
//
//  Protocol for receiving real-time parsing progress updates
//

import Foundation

/// Stages of the payslip parsing process
enum ParsingStage: String, CaseIterable {
    case preparing = "Preparing..."
    case extracting = "Analyzing payslip..."
    case validating = "Validating data..."
    case verifying = "Verifying accuracy..."
    case saving = "Saving payslip..."
    case completed = "Complete"
    case failed = "Failed"

    /// Estimated progress percentage for this stage
    var estimatedProgress: Double {
        switch self {
        case .preparing:
            return 0.05
        case .extracting:
            return 0.40
        case .validating:
            return 0.60
        case .verifying:
            return 0.80
        case .saving:
            return 0.95
        case .completed:
            return 1.0
        case .failed:
            return 0.0
        }
    }
}

/// Protocol for receiving parsing progress updates
@MainActor
protocol ParsingProgressDelegate: AnyObject {
    /// Called when the parsing stage changes
    /// - Parameters:
    ///   - stage: The current parsing stage
    ///   - progress: Progress percentage (0.0 to 1.0)
    func didUpdateProgress(stage: ParsingStage, progress: Double)

    /// Called when parsing completes successfully
    /// - Parameter payslip: The parsed payslip
    func didCompleteWithPayslip(_ payslip: PayslipItem)

    /// Called when parsing fails
    /// - Parameter error: The error that occurred
    func didFailWithError(_ error: Error)
}

/// Default implementations for optional methods
extension ParsingProgressDelegate {
    func didCompleteWithPayslip(_ payslip: PayslipItem) {}
    func didFailWithError(_ error: Error) {}
}

