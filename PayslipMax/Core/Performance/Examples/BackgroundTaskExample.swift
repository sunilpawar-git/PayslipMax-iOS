import Foundation
import SwiftUI
import Combine

/// Example showing how to use the TaskCoordinatorWrapper and ProgressReporterWrapper
/// for background task execution with progress tracking
public class PDFProcessingExample {
    
    // Progress updates publisher
    private let progressPublisher = PassthroughSubject<(progress: Double, message: String), Never>()
    private var cancellables = Set<AnyCancellable>()
    
    /// Process a PDF file with progress tracking
    /// - Parameters:
    ///   - url: URL of the PDF file to process
    ///   - progressHandler: Closure that receives progress updates
    /// - Returns: Processed data
    public func processPDF(url: URL, progressHandler: @escaping (Double, String) -> Void) async throws -> ProcessedData {
        // Create a wrapper for task coordinator
        let taskCoordinator = TaskCoordinatorWrapper.shared
        
        // Execute the task
        return try await taskCoordinator.executeTask(
            name: "Process PDF: \(url.lastPathComponent)",
            category: .processing,
            priority: .medium
        ) { progressCallback in
            // Perform the actual PDF processing
            return try await self.performPDFProcessing(url: url) { progress, message in
                // Forward progress to the task's progress handler
                progressCallback(progress, message)
                
                // Also forward to our own progress handler
                progressHandler(progress, message)
            }
        }
    }
    
    /// Process multiple PDFs with aggregated progress
    /// - Parameters:
    ///   - urls: URLs of PDF files to process
    ///   - progressHandler: Closure that receives progress updates
    /// - Returns: Array of processed data
    public func processMultiplePDFs(urls: [URL], progressHandler: @escaping (Double, String) -> Void) async throws -> [ProcessedData] {
        guard !urls.isEmpty else { return [] }
        
        // Create a wrapper for progress reporting
        let aggregateReporter = ProgressReporterWrapper(name: "MultiplePDFs")
        
        // Subscribe to progress updates
        aggregateReporter.progressPublisher
            .sink { update in
                progressHandler(update.progress, update.message)
            }
            .store(in: &cancellables)
        
        // Process each PDF and track progress
        var results: [ProcessedData] = []
        
        for (index, url) in urls.enumerated() {
            // Report which file we're processing
            aggregateReporter.updateWithStages(
                currentStage: index + 1, 
                totalStages: urls.count,
                stageProgress: 0,
                message: "Starting \(url.lastPathComponent)"
            )
            
            // Process the PDF with progress updating
            let data = try await processPDF(url: url) { progress, message in
                // Update the aggregate progress
                let stageProgress = progress
                aggregateReporter.updateWithStages(
                    currentStage: index + 1,
                    totalStages: urls.count,
                    stageProgress: stageProgress,
                    message: message
                )
            }
            
            results.append(data)
        }
        
        // Mark as complete
        aggregateReporter.complete(with: "Processed \(urls.count) PDFs")
        
        return results
    }
    
    // MARK: - Private Methods
    
    /// Perform the actual PDF processing (simulated)
    private func performPDFProcessing(url: URL, progressHandler: @escaping (Double, String) -> Void) async throws -> ProcessedData {
        // Simulate steps in processing
        try await simulateProcessingStep(progress: 0.1, message: "Loading PDF", progressHandler: progressHandler)
        try await simulateProcessingStep(progress: 0.3, message: "Extracting text", progressHandler: progressHandler)
        try await simulateProcessingStep(progress: 0.5, message: "Analyzing structure", progressHandler: progressHandler)
        try await simulateProcessingStep(progress: 0.7, message: "Extracting data", progressHandler: progressHandler)
        try await simulateProcessingStep(progress: 0.9, message: "Validating data", progressHandler: progressHandler)
        try await simulateProcessingStep(progress: 1.0, message: "Processing complete", progressHandler: progressHandler)
        
        // Return simulated data
        return ProcessedData(
            fileName: url.lastPathComponent,
            totalPages: Int.random(in: 1...10),
            processingTime: Double.random(in: 0.5...2.0)
        )
    }
    
    /// Simulate a processing step with a delay
    private func simulateProcessingStep(
        progress: Double,
        message: String,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        // Report progress
        progressHandler(progress, message)
        
        // Simulate work with a random delay
        try await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.1...0.5) * 1_000_000_000))
        
        // Randomly simulate an error (10% chance)
        if Double.random(in: 0...1) < 0.1 {
            throw ProcessingError.randomFailure(message: "Random failure during: \(message)")
        }
    }
    
    // MARK: - Models
    
    /// Represents processed data from a PDF
    public struct ProcessedData {
        public let fileName: String
        public let totalPages: Int
        public let processingTime: TimeInterval
    }
    
    /// Errors that can occur during processing
    public enum ProcessingError: Error, LocalizedError {
        case randomFailure(message: String)
        
        public var errorDescription: String? {
            switch self {
            case .randomFailure(let message):
                return "Processing failed: \(message)"
            }
        }
    }
}

// MARK: - Example SwiftUI View

/// SwiftUI view that demonstrates using the PDF processing example with task wrappers
public struct PDFProcessingExampleView: View {
    @State private var isProcessing = false
    @State private var progress = 0.0
    @State private var progressMessage = "Not started"
    @State private var results: [PDFProcessingExample.ProcessedData] = []
    @State private var error: Error?
    
    private let processor = PDFProcessingExample()
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("PDF Processing Example")
                .font(.headline)
            
            // Progress bar
            VStack {
                ProgressView(value: progress, total: 1.0)
                    .frame(height: 10)
                Text(progressMessage)
                    .font(.caption)
            }
            .padding()
            
            // Controls
            HStack {
                Button("Process Single PDF") {
                    processSinglePDF()
                }
                .disabled(isProcessing)
                
                Button("Process Multiple PDFs") {
                    processMultiplePDFs()
                }
                .disabled(isProcessing)
                
                Button("Stop") {
                    stopProcessing()
                }
                .disabled(!isProcessing)
            }
            
            // Results
            if !results.isEmpty {
                List {
                    ForEach(results, id: \.fileName) { result in
                        VStack(alignment: .leading) {
                            Text(result.fileName)
                                .font(.headline)
                            Text("\(result.totalPages) pages • \(String(format: "%.2f", result.processingTime))s")
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 200)
            }
            
            // Error display
            if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
    
    // Process a single PDF
    private func processSinglePDF() {
        guard !isProcessing else { return }
        
        isProcessing = true
        progress = 0.0
        progressMessage = "Starting..."
        error = nil
        
        // Create a simulated PDF URL
        let url = URL(string: "file:///example/document.pdf")!
        
        // Start the task
        Task {
            do {
                let result = try await processor.processPDF(url: url) { progress, message in
                    Task { @MainActor in
                        self.progress = progress
                        self.progressMessage = message
                    }
                }
                
                await MainActor.run {
                    results = [result]
                    isProcessing = false
                    progress = 1.0
                    progressMessage = "Complete"
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isProcessing = false
                    progressMessage = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Process multiple PDFs
    private func processMultiplePDFs() {
        guard !isProcessing else { return }
        
        isProcessing = true
        progress = 0.0
        progressMessage = "Starting multiple PDFs..."
        error = nil
        
        // Create simulated PDF URLs
        let urls = [
            URL(string: "file:///example/document1.pdf")!,
            URL(string: "file:///example/document2.pdf")!,
            URL(string: "file:///example/document3.pdf")!
        ]
        
        // Start the task
        Task {
            do {
                let results = try await processor.processMultiplePDFs(urls: urls) { progress, message in
                    Task { @MainActor in
                        self.progress = progress
                        self.progressMessage = message
                    }
                }
                
                await MainActor.run {
                    self.results = results
                    isProcessing = false
                    progress = 1.0
                    progressMessage = "Processed \(results.count) PDFs"
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isProcessing = false
                    progressMessage = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Stop processing
    private func stopProcessing() {
        // Cancel all processing tasks
        Task {
            await TaskCoordinatorWrapper.shared.cancelAllTasks(in: .processing)
            
            await MainActor.run {
                isProcessing = false
                progressMessage = "Processing cancelled"
            }
        }
    }
} 