import Foundation
import PDFKit
import UIKit

/// Default implementation of the PayslipProcessingPipeline
@MainActor
final class DefaultPayslipProcessingPipeline: PayslipProcessingPipeline {
    // MARK: - Properties
    
    /// Service for validating PDFs
    private let validationService: PayslipValidationServiceProtocol
    
    /// Service for extracting text from PDFs
    private let textExtractionService: PDFTextExtractionServiceProtocol
    
    /// Service for detecting payslip formats
    private let formatDetectionService: PayslipFormatDetectionServiceProtocol
    
    /// Factory for creating payslip processors
    private let processorFactory: PayslipProcessorFactory
    
    /// Track timing of pipeline stages for performance analysis
    private var stageTimings: [String: TimeInterval] = [:]
    
    // MARK: - Initialization
    
    /// Initialize with required services
    init(validationService: PayslipValidationServiceProtocol,
         textExtractionService: PDFTextExtractionServiceProtocol,
         formatDetectionService: PayslipFormatDetectionServiceProtocol,
         processorFactory: PayslipProcessorFactory) {
        self.validationService = validationService
        self.textExtractionService = textExtractionService
        self.formatDetectionService = formatDetectionService
        self.processorFactory = processorFactory
    }
    
    // MARK: - Pipeline Stage Implementation
    
    /// Validates the PDF data structure and checks if it's password protected
    func validatePDF(_ data: Data) async -> Result<Data, PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["validate"] = Date().timeIntervalSince(startTime)
            print("[PayslipProcessingPipeline] Validation stage completed in \(stageTimings["validate"]!) seconds")
        }
        
        // Validate that this is a valid PDF structure
        guard validationService.validatePDFStructure(data) else {
            print("[PayslipProcessingPipeline] Invalid PDF structure")
            return .failure(.invalidPDFStructure)
        }
        
        // Check if the PDF is password-protected
        if validationService.isPDFPasswordProtected(data) {
            print("[PayslipProcessingPipeline] PDF is password-protected")
            return .failure(.passwordProtected)
        }
        
        return .success(data)
    }
    
    /// Extracts text from the PDF data
    func extractText(_ data: Data) async -> Result<(Data, String), PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["extract"] = Date().timeIntervalSince(startTime)
            print("[PayslipProcessingPipeline] Text extraction stage completed in \(stageTimings["extract"]!) seconds")
        }
        
        // Extract text from the PDF
        do {
            let extractedText = try textExtractionService.extractText(from: data)
            
            // Validate that the extracted text contains payslip content
            let validationResult = validationService.validatePayslipContent(extractedText)
            guard validationResult.isValid else {
                print("[PayslipProcessingPipeline] PDF does not appear to be a payslip")
                return .failure(.notAPayslip)
            }
            
            print("[PayslipProcessingPipeline] Extracted \(extractedText.count) characters of text from PDF")
            return .success((data, extractedText))
        } catch {
            print("[PayslipProcessingPipeline] Failed to extract text from PDF: \(error)")
            return .failure(.textExtractionFailed)
        }
    }
    
    /// Detects the format of the payslip based on the extracted text
    func detectFormat(_ data: Data, text: String) async -> Result<(Data, String, PayslipFormat), PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["detect"] = Date().timeIntervalSince(startTime)
            print("[PayslipProcessingPipeline] Format detection stage completed in \(stageTimings["detect"]!) seconds")
        }
        
        let format = formatDetectionService.detectFormat(fromText: text)
        print("[PayslipProcessingPipeline] Detected format: \(format)")
        
        return .success((data, text, format))
    }
    
    /// Processes the payslip based on the detected format
    func processPayslip(_ data: Data, text: String, format: PayslipFormat) async -> Result<PayslipItem, PDFProcessingError> {
        let startTime = Date()
        defer {
            stageTimings["process"] = Date().timeIntervalSince(startTime)
            print("[PayslipProcessingPipeline] Processing stage completed in \(stageTimings["process"]!) seconds")
        }
        
        // Get the appropriate processor for this payslip format
        let processor = processorFactory.getProcessor(for: format)
        
        // Process the payslip using the selected processor
        do {
            let payslipItem = try processor.processPayslip(from: text)
            
            // Set the PDF data
            payslipItem.pdfData = data
            
            return .success(payslipItem)
        } catch {
            print("[PayslipProcessingPipeline] Error processing payslip: \(error)")
            return .failure(.processingFailed)
        }
    }
    
    /// Executes the full pipeline from validation to processing
    func executePipeline(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        let overallStartTime = Date()
        defer {
            let totalTime = Date().timeIntervalSince(overallStartTime)
            stageTimings["total"] = totalTime
            print("[PayslipProcessingPipeline] Total pipeline execution time: \(totalTime) seconds")
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