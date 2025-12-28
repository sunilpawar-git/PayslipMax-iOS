//
//  VisionLLMPayslipParser+ProgressReporting.swift
//  PayslipMax
//
//  Progress reporting extension for VisionLLMPayslipParser
//

import Foundation

extension VisionLLMPayslipParser {
    // MARK: - Progress Reporting

    func reportProgress(_ stage: ParsingStage) async {
        await MainActor.run { progressDelegate?.didUpdateProgress(stage: stage, progress: stage.estimatedProgress) }
    }

    func reportCompletion(_ payslip: PayslipItem) async {
        await MainActor.run {
            progressDelegate?.didUpdateProgress(stage: .completed, progress: 1.0)
            progressDelegate?.didCompleteWithPayslip(payslip)
        }
    }

    func reportError(_ error: Error) async {
        await MainActor.run {
            progressDelegate?.didUpdateProgress(stage: .failed, progress: 0.0)
            progressDelegate?.didFailWithError(error)
        }
    }
}

