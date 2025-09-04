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
        
        // Register all available processors
        self.processors = [
            PSUPayslipProcessor(),
            CorporatePayslipProcessor()
        ]
    }
    
    // MARK: - Public Methods
    
    /// Gets the appropriate processor for the provided text
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: The most appropriate processor
    func getProcessor(for text: String) -> PayslipProcessorProtocol {
        print("[PayslipProcessorFactory] Determining best processor for text with \(text.count) characters")
        
        // First, check if the format detection service can identify the format
        let detectedFormat = formatDetectionService.detectFormat(fromText: text)
        print("[PayslipProcessorFactory] Format detected by service: \(detectedFormat)")
        
        // Find processor for the detected format
        if let processor = processors.first(where: { $0.handlesFormat == detectedFormat }) {
            return processor
        }
        
        // If format detection service couldn't determine or no matching processor, 
        // calculate confidence scores for each processor
        var bestProcessor: PayslipProcessorProtocol?
        var highestConfidence: Double = 0.0
        
        for processor in processors {
            let confidence = processor.canProcess(text: text)
            print("[PayslipProcessorFactory] Processor for \(processor.handlesFormat) confidence: \(confidence)")
            
            if confidence > highestConfidence {
                highestConfidence = confidence
                bestProcessor = processor
            }
        }
        
        // If we found a processor with some confidence, use it
        if let bestProcessor = bestProcessor, highestConfidence > 0.1 {
            print("[PayslipProcessorFactory] Selected processor for format: \(bestProcessor.handlesFormat)")
            return bestProcessor
        }
        
        // Default to corporate format if we couldn't determine
        print("[PayslipProcessorFactory] Defaulting to corporate format processor")
        return getDefaultProcessor()
    }
    
    /// Returns a specific processor for a given format
    /// - Parameter format: The payslip format
    /// - Returns: A processor that can handle the format, or the default processor if none found
    func getProcessor(for format: PayslipFormat) -> PayslipProcessorProtocol {
        if let processor = processors.first(where: { $0.handlesFormat == format }) {
            return processor
        }
        
        return getDefaultProcessor()
    }
    
    /// Gets all available processors
    /// - Returns: Array of all registered processors
    func getAllProcessors() -> [PayslipProcessorProtocol] {
        return processors
    }
    
    // MARK: - Private Methods
    
    /// Returns the default processor to use when no specific format is detected
    /// - Returns: The default processor (corporate)
    private func getDefaultProcessor() -> PayslipProcessorProtocol {
        return processors.first(where: { $0.handlesFormat == .corporate }) ?? processors[0]
    }
} 