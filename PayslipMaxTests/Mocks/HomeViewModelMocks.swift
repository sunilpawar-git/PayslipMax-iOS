import Foundation
@testable import PayslipMax

// MARK: - Home ViewModel Mocks Entry Point

/// Entry point for all Home ViewModel related mock classes.
/// This file imports and organizes all mock components for Home ViewModel testing.
///
/// The mock classes have been extracted into separate files following SOLID principles:
/// - MockPDFProcessingHandler: Handles PDF processing mocks
/// - MockPayslipDataHandler: Handles data management mocks
/// - MockChartDataPreparationService: Handles chart data mocks
/// - MockPasswordProtectedPDFHandler: Handles password protection mocks
/// - MockErrorHandler: Handles error management mocks
/// - MockHomeNavigationCoordinator: Handles navigation mocks
/// - MockPayslipModels: Contains data models like AnyPayslip
/// - MockUtilities: Contains utility classes and extensions
///
/// This organization ensures each mock has a single responsibility and
/// maintains the architectural constraint of <300 lines per file.

@_exported import struct Foundation.Notification

// Re-export all mock classes for easy importing in tests
// These classes are defined in their respective files in this Mocks directory
