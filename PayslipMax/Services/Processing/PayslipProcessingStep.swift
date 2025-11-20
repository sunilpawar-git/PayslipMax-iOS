import Foundation
import PDFKit

/// Protocol defining a single step in the payslip processing pipeline.
///
/// This protocol represents a key building block in the modular processing architecture,
/// enabling the creation of focused, reusable processing components that can be
/// composed into complex pipelines. Each step takes a specific input type and produces
/// a specific output type, allowing for strong type safety through the pipeline.
///
/// Processing steps should be designed to perform a single responsibility in the
/// overall processing workflow, such as validation, text extraction, format detection,
/// or data processing.
protocol PayslipProcessingStep {
    /// The type of input this step accepts
    associatedtype Input

    /// The type of output this step produces
    associatedtype Output

    /// Process the input and produce an output
    /// - Parameter input: The input to this step
    /// - Returns: A result containing either the output or an error
    @MainActor
    func process(_ input: Input) async -> Result<Output, PDFProcessingError>
}

/// A type-erased processing step that can be used in a sequence.
///
/// This class uses type erasure to allow processing steps with different input/output types
/// to be composed together in a pipeline. It preserves the type safety of the pipeline
/// while enabling flexible pipeline composition.
@MainActor
class AnyPayslipProcessingStep<I, O> {
    /// The function that processes input and produces output
    private let processingFunction: (I) async -> Result<O, PDFProcessingError>

    /// Initialize with a processing function
    /// - Parameter processor: The function that processes input
    /// - Note: This initializer takes a concrete `PayslipProcessingStep` and wraps its processing function
    init<S: PayslipProcessingStep>(_ step: S) where S.Input == I, S.Output == O {
        self.processingFunction = step.process
    }

    /// Process the input
    /// - Parameter input: The input to process
    /// - Returns: A result with either the output or an error
    func process(_ input: I) async -> Result<O, PDFProcessingError> {
        return await processingFunction(input)
    }
}

/// A concrete implementation of a processing step that wraps a closure.
///
/// This class allows for creating processing steps from closures, which is useful for
/// creating simple steps or for testing. It provides a way to integrate custom processing
/// logic without creating a full class implementation.
@MainActor
class ClosureProcessingStep<I, O>: PayslipProcessingStep {
    typealias Input = I
    typealias Output = O

    /// The closure that processes input
    private let processingClosure: (I) async -> Result<O, PDFProcessingError>

    /// Initialize with a processing closure
    /// - Parameter processor: The closure that processes input
    init(processor: @escaping (I) async -> Result<O, PDFProcessingError>) {
        self.processingClosure = processor
    }

    /// Process the input using the stored closure
    /// - Parameter input: The input to process
    /// - Returns: The result from the closure
    func process(_ input: I) async -> Result<O, PDFProcessingError> {
        return await processingClosure(input)
    }
}

/// A concrete processing step for processing payslips.
///
/// This step is responsible for creating a `PayslipItem` from the extracted text
/// using the appropriate processor for the detected format. It represents the final
/// stage in the payslip processing pipeline where the structured data is extracted
/// from the raw text.
@MainActor
class PayslipProcessingStepImpl: PayslipProcessingStep {
    typealias Input = (Data, String, PayslipFormat)
    typealias Output = PayslipItem

    /// Factory for creating format-specific processors
    private let processorFactory: PayslipProcessorFactory

    /// Initialize with a processor factory
    /// - Parameter processorFactory: The factory to use for creating payslip processors
    init(processorFactory: PayslipProcessorFactory) {
        self.processorFactory = processorFactory
    }

    /// Process the input by creating a payslip item
    /// - Parameter input: Tuple of (PDF data, extracted text, detected format)
    /// - Returns: Success with processed payslip or failure with error
    /// - Note: This method logs performance metrics and handles errors during processing
    func process(_ input: (Data, String, PayslipFormat)) async -> Result<PayslipItem, PDFProcessingError> {
        let (data, text, format) = input
        let startTime = Date()
        defer {
            print("[PayslipProcessingStep] Completed in \(Date().timeIntervalSince(startTime)) seconds")
        }

        // Get the appropriate processor for this payslip format
        let processor = processorFactory.getProcessor(for: format)

        // Process the payslip using the selected processor
        do {
            let payslipItem = try await processor.processPayslip(from: text)

            // Set the PDF data
            payslipItem.pdfData = data

            return .success(payslipItem)
        } catch {
            print("[PayslipProcessingStep] Error processing payslip: \(error)")
            return .failure(.processingFailed)
        }
    }
}
