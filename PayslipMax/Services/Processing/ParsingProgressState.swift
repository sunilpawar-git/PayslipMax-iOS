//
//  ParsingProgressState.swift
//  PayslipMax
//
//  Progress state for payslip parsing operations - extracted for 300-line compliance
//

import Foundation

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

