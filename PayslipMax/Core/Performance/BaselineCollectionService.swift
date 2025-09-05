import Foundation
import PDFKit

/// Service to coordinate baseline collection and establish performance standards
/// 
/// This service orchestrates the baseline collection process for Phase 0 Target 2
/// of the parsing system unification plan. It ensures consistent measurement
/// and provides the foundation for regression detection.
@MainActor
final class BaselineCollectionService {
    
    // MARK: - Properties
    
    private let metricsCollector: BaselineMetricsCollector
    private let regressionDetector: PerformanceRegressionDetector
    
    /// Current baseline snapshot
    private(set) var currentBaseline: BaselineSnapshot?
    
    /// Baseline collection history
    private(set) var baselineHistory: [BaselineSnapshot] = []
    
    // MARK: - Initialization
    
    init(
        metricsCollector: BaselineMetricsCollector? = nil,
        regressionDetector: PerformanceRegressionDetector? = nil
    ) {
        self.metricsCollector = metricsCollector ?? BaselineMetricsCollector()
        self.regressionDetector = regressionDetector ?? PerformanceRegressionDetector()
    }
    
    // MARK: - Baseline Collection
    
    /// Establish baseline metrics for the parsing system unification
    /// This implements Phase 0 Target 2 requirements
    func establishBaseline() async throws {
        print("🎯 Starting Phase 0 Target 2: Performance Baseline Establishment")
        
        // Create test documents for consistent measurement
        let testDocuments = try await BaselineTestDocumentProvider.createTestDocumentSet()
        print("📄 Created test document set with \(testDocuments.count) documents")
        
        // Collect comprehensive baseline metrics
        let baseline = try await metricsCollector.collectBaselineMetrics(testDocuments: testDocuments)
        
        // Store baseline
        currentBaseline = baseline
        baselineHistory.append(baseline)
        
        // Configure regression detector with baseline
        regressionDetector.setBaseline(baseline)
        
        // Save baseline to disk for persistence
        try await saveBaselineToFile(baseline)
        
        // Generate and log baseline report
        let report = baseline.generateSummaryReport()
        print("📊 Baseline establishment completed:\n\(report)")
        
        // Validate baseline quality
        try validateBaselineQuality(baseline)
        
        print("✅ Phase 0 Target 2 completed successfully")
    }
    
    /// Validate current performance against established baseline
    /// - Returns: Regression analysis results
    func validateCurrentPerformance() async throws -> RegressionAnalysis {
        guard currentBaseline != nil else {
            throw BaselineCollectionError.noBaselineEstablished
        }
        
        print("🔍 Validating current performance against baseline")
        
        // Collect current metrics using same test documents
        let testDocuments = try await BaselineTestDocumentProvider.createTestDocumentSet()
        let currentMetrics = try await metricsCollector.collectBaselineMetrics(testDocuments: testDocuments)
        
        // Detect regressions
        let regressionAnalysis = try regressionDetector.detectRegressions(currentMetrics: currentMetrics)
        
        // Log results
        let report = regressionAnalysis.generateReport()
        print("📈 Performance validation completed:\n\(report)")
        
        return regressionAnalysis
    }
    
    
    // MARK: - Baseline Persistence
    
    /// Save baseline to file for persistence across app sessions
    private func saveBaselineToFile(_ baseline: BaselineSnapshot) async throws {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let documentsURL = documentsURL else {
            throw BaselineCollectionError.fileSystemError("Could not access documents directory")
        }
        
        let baselineURL = documentsURL.appendingPathComponent("performance_baseline.json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(baseline)
            try data.write(to: baselineURL)
            
            print("💾 Baseline saved to: \(baselineURL.path)")
        } catch {
            print("❌ Failed to save baseline: \(error.localizedDescription)")
            throw BaselineCollectionError.fileSystemError("Failed to save baseline: \(error.localizedDescription)")
        }
    }
    
    /// Load baseline from file if available
    func loadBaselineFromFile() async throws -> BaselineSnapshot? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let documentsURL = documentsURL else { return nil }
        
        let baselineURL = documentsURL.appendingPathComponent("performance_baseline.json")
        
        guard FileManager.default.fileExists(atPath: baselineURL.path) else {
            print("📄 No existing baseline file found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: baselineURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let baseline = try decoder.decode(BaselineSnapshot.self, from: data)
            
            currentBaseline = baseline
            regressionDetector.setBaseline(baseline)
            
            print("📊 Baseline loaded from file: \(baseline.timestamp)")
            return baseline
        } catch {
            print("❌ Failed to load baseline: \(error.localizedDescription)")
            throw BaselineCollectionError.fileSystemError("Failed to load baseline: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Baseline Validation
    
    /// Validate that the baseline meets quality standards
    private func validateBaselineQuality(_ baseline: BaselineSnapshot) throws {
        var issues: [String] = []
        
        // Validate parsing metrics
        if baseline.parsingMetrics.systemCount < 4 {
            issues.append("Expected 4 parsing systems, found \(baseline.parsingMetrics.systemCount)")
        }
        
        if baseline.parsingMetrics.averageProcessingTime <= 0 {
            issues.append("Invalid average processing time: \(baseline.parsingMetrics.averageProcessingTime)")
        }
        
        // Validate cache metrics
        if baseline.cacheMetrics.cacheSystemCount < 6 {
            issues.append("Expected 6 cache systems, found \(baseline.cacheMetrics.cacheSystemCount)")
        }
        
        if baseline.cacheMetrics.overallHitRate < 0 || baseline.cacheMetrics.overallHitRate > 1 {
            issues.append("Invalid cache hit rate: \(baseline.cacheMetrics.overallHitRate)")
        }
        
        // Validate memory metrics
        if baseline.memoryMetrics.peakMemoryUsage == 0 {
            issues.append("No memory usage recorded")
        }
        
        // Validate test coverage
        if baseline.testDocumentCount < 1 {
            issues.append("Insufficient test documents: \(baseline.testDocumentCount)")
        }
        
        if !issues.isEmpty {
            let errorMessage = "Baseline quality issues: " + issues.joined(separator: ", ")
            print("❌ \(errorMessage)")
            throw BaselineCollectionError.invalidBaseline(errorMessage)
        }
        
        print("✅ Baseline quality validation passed")
    }
}

// MARK: - Error Types

enum BaselineCollectionError: Error, LocalizedError {
    case noBaselineEstablished
    case invalidBaseline(String)
    case fileSystemError(String)
    case testDocumentCreationError(String)
    
    var errorDescription: String? {
        switch self {
        case .noBaselineEstablished:
            return "No baseline has been established. Call establishBaseline() first."
        case .invalidBaseline(let reason):
            return "Invalid baseline: \(reason)"
        case .fileSystemError(let reason):
            return "File system error: \(reason)"
        case .testDocumentCreationError(let reason):
            return "Test document creation error: \(reason)"
        }
    }
}
