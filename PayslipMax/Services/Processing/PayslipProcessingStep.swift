import Foundation
import PDFKit

/// A protocol defining a single step in the payslip processing pipeline (non-UI).
/// Steps run off the main thread unless a specific step needs main-thread access.
protocol PayslipProcessingStep {
    associatedtype Input
    associatedtype Output
    func process(_ input: Input) async -> Result<Output, PDFProcessingError>
}

/// A type-erased processing step that can be used in a sequence.
final class AnyPayslipProcessingStep<I, O> {
    private let processingFunction: (I) async -> Result<O, PDFProcessingError>
    init<S: PayslipProcessingStep>(_ step: S) where S.Input == I, S.Output == O {
        self.processingFunction = step.process
    }
    func process(_ input: I) async -> Result<O, PDFProcessingError> {
        return await processingFunction(input)
    }
}

/// A concrete implementation of a processing step that wraps a closure.
final class ClosureProcessingStep<I, O>: PayslipProcessingStep {
    typealias Input = I
    typealias Output = O
    private let processingClosure: (I) async -> Result<O, PDFProcessingError>
    init(processor: @escaping (I) async -> Result<O, PDFProcessingError>) {
        self.processingClosure = processor
    }
    func process(_ input: I) async -> Result<O, PDFProcessingError> {
        return await processingClosure(input)
    }
}

/// A concrete processing step for processing payslips.
final class PayslipProcessingStepImpl: PayslipProcessingStep {
    typealias Input = (Data, String, PayslipFormat)
    typealias Output = PayslipItem
    private let processorFactory: PayslipProcessorFactory
    init(processorFactory: PayslipProcessorFactory) {
        self.processorFactory = processorFactory
    }
    func process(_ input: (Data, String, PayslipFormat)) async -> Result<PayslipItem, PDFProcessingError> {
        let (data, text, format) = input
        let startTime = Date()
        defer { print("[PayslipProcessingStep] Completed in \(Date().timeIntervalSince(startTime)) seconds") }
        let processor = processorFactory.getProcessor(for: format)
        do {
            let payslipItem = try processor.processPayslip(from: text)
            payslipItem.pdfData = data
            return .success(payslipItem)
        } catch {
            print("[PayslipProcessingStep] Error processing payslip: \(error)")
            return .failure(.processingFailed)
        }
    }
}