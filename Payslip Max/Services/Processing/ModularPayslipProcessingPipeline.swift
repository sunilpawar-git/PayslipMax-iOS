import Foundation
import PDFKit
import UIKit

/// A modular pipeline that can be composed of individual processing steps
@MainActor
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
    
    /// Initialize with individual processing steps
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
    
    /// Initialize with services, creating concrete processing steps
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
    
    /// Validates the PDF data to ensure it's properly formatted
    func validatePDF(_ data: Data) async -> Result<Data, PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["validate"] = Date().timeIntervalSince(startTime)
        }
        
        return await validationStep.process(data)
    }
    
    /// Extracts text from the PDF data
    func extractText(_ data: Data) async -> Result<(Data, String), PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["extract"] = Date().timeIntervalSince(startTime)
        }
        
        return await textExtractionStep.process(data)
    }
    
    /// Detects the format of the payslip based on the extracted text
    func detectFormat(_ data: Data, text: String) async -> Result<(Data, String, PayslipFormat), PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["detect"] = Date().timeIntervalSince(startTime)
        }
        
        return await formatDetectionStep.process((data, text))
    }
    
    /// Processes the payslip based on the detected format
    func processPayslip(_ data: Data, text: String, format: PayslipFormat) async -> Result<PayslipItem, PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["process"] = Date().timeIntervalSince(startTime)
        }
        
        return await processingStep.process((data, text, format))
    }
    
    /// Executes the full pipeline from validation to processing
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