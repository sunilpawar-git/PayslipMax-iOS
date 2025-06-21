import Foundation

/// Extended document analysis result with memory optimization info
struct DocumentAnalysisResult {
    let pageCount: Int
    let isLargeDocument: Bool
    let estimatedMemoryRequirement: Int64
    let hasScannedContent: Bool
    let hasTabularData: Bool
    let hasFormElements: Bool
    let isComplexLayout: Bool
    let columnCount: Int
    let textDensity: Double
    let processingRecommendation: ProcessingRecommendation
    let sampledPageIndices: [Int]
    let analysisTimestamp: Date
    
    enum ProcessingRecommendation {
        case useStandardProcessing
        case useStreamingMode
        case useOCRWithBatching
        case useStructuredExtraction
        
        var description: String {
            switch self {
            case .useStandardProcessing:
                return "Standard processing suitable for this document"
            case .useStreamingMode:
                return "Use streaming mode for memory efficiency"
            case .useOCRWithBatching:
                return "Use OCR with batching for scanned content"
            case .useStructuredExtraction:
                return "Use structured extraction for complex layout"
            }
        }
    }
}