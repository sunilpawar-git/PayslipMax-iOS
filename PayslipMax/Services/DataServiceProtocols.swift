import Foundation
import SwiftData

/// Comprehensive error types for data service operations.
/// Provides detailed error information for debugging and user feedback.
enum DataError: LocalizedError {
    /// Service has not been properly initialized
    case notInitialized
    /// Attempted operation on an unsupported data type
    case unsupportedType
    /// Error occurred during save operation
    case saveFailed(Error)
    /// Error occurred during fetch operation
    case fetchFailed(Error)
    /// Error occurred during delete operation
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Data service not initialized"
        case .unsupportedType:
            return "Unsupported data type"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        }
    }
}

/// Note: PayslipRepositoryProtocol is defined in Services/Repositories/PayslipRepositoryProtocol.swift
/// This file contains only the DataError enum and any additional data service protocols.
