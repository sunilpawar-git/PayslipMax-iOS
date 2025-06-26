import Foundation

/// Mock implementation of PayslipFormatDetectionServiceProtocol for testing purposes.
///
/// This mock service provides controllable format detection behavior for testing
/// various payslip format scenarios. It allows setting the format to return
/// and provides consistent detection results.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    
    // MARK: - Properties
    
    /// The format to return from detection operations
    var mockFormat: PayslipFormat = .standard
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        mockFormat = .standard
    }
    
    // MARK: - PayslipFormatDetectionServiceProtocol Implementation
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        return mockFormat
    }
    
    func detectFormat(fromText text: String) -> PayslipFormat {
        return mockFormat
    }
} 