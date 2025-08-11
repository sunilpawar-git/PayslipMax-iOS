import Foundation
import PDFKit
import UIKit

/// A modular pipeline that can be composed of individual processing steps.
///
/// This class implements a flexible, extensible payslip processing pipeline using a modular architecture.
/// It coordinates multiple specialized processing steps in sequence to transform raw PDF data into 
/// structured payslip information. Each step in the pipeline has a specific responsibility and 
/// well-defined input/output types, enabling:
///
/// - Clear separation of concerns
/// - Independent testing of each processing component
/// - Easy extension with new processing capabilities
/// - Performance monitoring at each stage
///
/// The pipeline follows these sequential stages:
/// 1. PDF validation - Ensures the PDF is valid and accessible
/// 2. Text extraction - Extracts text content from the PDF
/// 3. Format detection - Identifies the specific payslip format
/// 4. Payslip processing - Extracts structured data based on the format
///
/// Each stage passes its results to the next stage, with error handling at each transition.
final class ModularPayslipProcessingPipeline: PayslipProcessingPipeline {
    // MARK: - Properties
    
    /// The validation step
    private let validationStep: AnyPayslipProcessingStep<Data, Data>
    
    /// The text extraction step
    private let textExtractionStep: AnyPayslipProcessingStep<Data, (Data, String)>
    
    /// The format detection step
    private let formatDetectionStep: AnyPayslipProcessingStep<(Data, String), (Data, String, PayslipFormat)>
    
    /// The processing step
    private let processingStep: AnyPayslipProcessingStep<(Data, String, PayslipFormat), PayslipItem>
    
    /// Track timing of pipeline stages for performance analysis
    private var stageTimings: [String: TimeInterval] = [:]
    
    // MARK: - Initialization
    
    /// Initialize with individual processing steps.
    ///
    /// This initializer allows complete customization of the pipeline by injecting
    /// specific implementations for each processing step.
    ///
    /// - Parameters:
    ///   - validationStep: The step that validates PDF data
    ///   - textExtractionStep: The step that extracts text from validated PDF data
    ///   - formatDetectionStep: The step that detects the payslip format from extracted text
    ///   - processingStep: The step that processes the payslip based on its format
    init(
        validationStep: AnyPayslipProcessingStep<Data, Data>,
        textExtractionStep: AnyPayslipProcessingStep<Data, (Data, String)>,
        formatDetectionStep: AnyPayslipProcessingStep<(Data, String), (Data, String, PayslipFormat)>,
        processingStep: AnyPayslipProcessingStep<(Data, String, PayslipFormat), PayslipItem>
    ) {
        self.validationStep = validationStep
        self.textExtractionStep = textExtractionStep
        self.formatDetectionStep = formatDetectionStep
        self.processingStep = processingStep
    }
    
    /// Initialize with services, creating concrete processing steps.
    ///
    /// This convenience initializer creates appropriate processing steps from the provided services,
    /// simplifying pipeline construction with standard components.
    ///
    /// - Parameters:
    ///   - validationService: Service for validating PDF documents
    ///   - textExtractionService: Service for extracting text from PDFs
    ///   - formatDetectionService: Service for detecting payslip formats
    ///   - processorFactory: Factory for creating format-specific payslip processors
    convenience init(
        validationService: PayslipValidationServiceProtocol,
        textExtractionService: PDFTextExtractionServiceProtocol,
        formatDetectionService: PayslipFormatDetectionServiceProtocol,
        processorFactory: PayslipProcessorFactory
    ) {
        // Create concrete processing steps
        let validationStep = ValidationProcessingStep(validationService: validationService)
        
        let textExtractionStep = TextExtractionProcessingStep(
            textExtractionService: textExtractionService,
            validationService: validationService
        )
        
        let formatDetectionStep = FormatDetectionProcessingStep(
            formatDetectionService: formatDetectionService
        )
        
        let processingStep = PayslipProcessingStepImpl(
            processorFactory: processorFactory
        )
        
        // Initialize with type-erased steps
        self.init(
            validationStep: AnyPayslipProcessingStep(validationStep),
            textExtractionStep: AnyPayslipProcessingStep(textExtractionStep),
            formatDetectionStep: AnyPayslipProcessingStep(formatDetectionStep),
            processingStep: AnyPayslipProcessingStep(processingStep)
        )
    }
    
    // MARK: - Pipeline Stage Implementation
    
    /// Validates the PDF data to ensure it's properly formatted.
    ///
    /// - Parameter data: The PDF data to validate
    /// - Returns: Success with validated data or failure with error
    /// - Note: Measures and tracks execution time for performance analysis
    func validatePDF(_ data: Data) async -> Result<Data, PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["validate"] = Date().timeIntervalSince(startTime)
        }
        
        return await validationStep.process(data)
    }
    
    /// Extracts text from the PDF data.
    ///
    /// - Parameter data: The validated PDF data
    /// - Returns: Success with tuple of (PDF data, extracted text) or failure with error
    /// - Note: Measures and tracks execution time for performance analysis
    func extractText(_ data: Data) async -> Result<(Data, String), PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["extract"] = Date().timeIntervalSince(startTime)
        }
        
        return await textExtractionStep.process(data)
    }
    
    /// Detects the format of the payslip based on the extracted text.
    ///
    /// - Parameters:
    ///   - data: The PDF data
    ///   - text: The extracted text
    /// - Returns: Success with tuple of (PDF data, extracted text, detected format) or failure with error
    /// - Note: Measures and tracks execution time for performance analysis 
    func detectFormat(_ data: Data, text: String) async -> Result<(Data, String, PayslipFormat), PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["detect"] = Date().timeIntervalSince(startTime)
        }
        
        return await formatDetectionStep.process((data, text))
    }
    
    /// Processes the payslip based on the detected format.
    ///
    /// - Parameters:
    ///   - data: The PDF data
    ///   - text: The extracted text
    ///   - format: The detected payslip format
    /// - Returns: Success with processed payslip or failure with error
    /// - Note: Measures and tracks execution time for performance analysis
    func processPayslip(_ data: Data, text: String, format: PayslipFormat) async -> Result<PayslipItem, PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["process"] = Date().timeIntervalSince(startTime)
        }
        
        return await processingStep.process((data, text, format))
    }
    
    /// Executes the full pipeline from validation to processing.
    ///
    /// This method coordinates the entire processing pipeline, executing each stage in sequence
    /// and handling the transitions between stages, including error conditions. It provides
    /// comprehensive timing information for performance analysis.
    ///
    /// - Parameter data: The PDF data to process
    /// - Returns: Success with processed payslip or failure with error
    /// - Note: Measures and tracks overall execution time and reports detailed performance metrics
    func executePipeline(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        let overallStartTime = Date()
        defer {
            let totalTime = Date().timeIntervalSince(overallStartTime)
            stageTimings["total"] = totalTime
            print("[ModularPipeline] Total pipeline execution time: \(totalTime) seconds")
        }
        
        // Step 1: Validate PDF
        let validationResult = await validatePDF(data)
        switch validationResult {
        case .success(let validatedData):
            // Step 2: Extract text
            let extractionResult = await extractText(validatedData)
            switch extractionResult {
            case .success(let (extractedData, extractedText)):
                // Step 3: Detect format
                let formatResult = await detectFormat(extractedData, text: extractedText)
                switch formatResult {
                case .success(let (formattedData, formattedText, detectedFormat)):
                    // Step 4: Process payslip
                    return await processPayslip(formattedData, text: formattedText, format: detectedFormat)
                case .failure(let error):
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
} 