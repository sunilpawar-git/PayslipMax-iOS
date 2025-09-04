import Foundation

/// Factory for creating and managing payslip processors
class PayslipProcessorFactory {
    // MARK: - Properties
    
    /// Available processors
    private let processors: [PayslipProcessorProtocol]
    
    /// Format detection service
    private let formatDetectionService: PayslipFormatDetectionServiceProtocol
    
    // MARK: - Initialization
    
    /// Initialize with the format detection service
    /// - Parameter formatDetectionService: Service for detecting payslip formats
    init(formatDetectionService: PayslipFormatDetectionServiceProtocol) {
        self.formatDetectionService = formatDetectionService
        
        // Register unified military processor for all defense personnel payslips
        self.processors = [
            UnifiedMilitaryPayslipProcessor()
        ]
    }
    
    // MARK: - Public Methods
    
    /// Gets the appropriate processor for the provided text
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: The unified military processor (only processor for defense personnel)
    func getProcessor(for text: String) -> PayslipProcessorProtocol {
        // Since PayslipMax is exclusively for defense personnel, always return the unified military processor
        print("[PayslipProcessorFactory] Using unified military processor for defense personnel payslip")
        return processors[0]  // UnifiedMilitaryPayslipProcessor
    }
    
    /// Returns a specific processor for a given format
    /// - Parameter format: The payslip format
    /// - Returns: The unified military processor (handles all defense formats)
    func getProcessor(for format: PayslipFormat) -> PayslipProcessorProtocol {
        // Always return unified military processor for any defense-related format
        return processors[0]  // UnifiedMilitaryPayslipProcessor
    }
    
    /// Gets all available processors
    /// - Returns: Array of all registered processors
    func getAllProcessors() -> [PayslipProcessorProtocol] {
        return processors
    }
    
    // MARK: - Private Methods
    
    /// Returns the default processor to use when no specific format is detected
    /// - Returns: The unified military processor (only processor for defense personnel)
    private func getDefaultProcessor() -> PayslipProcessorProtocol {
        return processors[0]  // Always return unified military processor
    }
} 