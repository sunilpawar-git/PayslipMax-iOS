import Foundation
import PDFKit

/// Protocol for extraction strategy selection
protocol ExtractionStrategySelectorProtocol {
    /// Selects the optimal extraction strategy for a given document
    /// - Parameters:
    ///   - document: The PDF document to analyze
    ///   - userPreferences: User-specified preferences for extraction
    /// - Returns: The recommended extraction strategy and options
    func selectOptimalStrategy(
        for document: PDFDocument,
        userPreferences: ExtractionPreferences?
    ) async -> StrategyRecommendation
    
    /// Analyzes document characteristics for strategy selection
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Document analysis results
    func analyzeDocument(_ document: PDFDocument) async -> StrategyDocumentAnalysis
}

/// Represents user preferences for extraction strategy selection
struct ExtractionPreferences {
    let priority: ExtractionPriority
    let memoryEfficiencyRequired: Bool
    let qualityThreshold: Double
    
    init(priority: ExtractionPriority = .balanced, 
         memoryEfficiencyRequired: Bool = false, 
         qualityThreshold: Double = 0.85) {
        self.priority = priority
        self.memoryEfficiencyRequired = memoryEfficiencyRequired
        self.qualityThreshold = qualityThreshold
    }
}

/// Priority levels for extraction strategy selection
enum ExtractionPriority {
    case speed
    case quality  
    case memoryEfficient
    case balanced
}

/// Strategy recommendation result
struct StrategyRecommendation {
    let strategy: TextExtractionStrategy
    let confidence: Double
    let alternatives: [TextExtractionStrategy]
    let reasoning: String
    
    init(strategy: TextExtractionStrategy, 
         confidence: Double, 
         alternatives: [TextExtractionStrategy] = [], 
         reasoning: String = "") {
        self.strategy = strategy
        self.confidence = confidence
        self.alternatives = alternatives
        self.reasoning = reasoning
    }
}

/// Document analysis results for strategy selection
struct StrategyDocumentAnalysis {
    let pageCount: Int
    let estimatedSize: Int64
    let contentComplexity: ContentComplexity
    let hasImages: Bool
    let hasTables: Bool
    let textQuality: TextQuality
    
    init(pageCount: Int, 
         estimatedSize: Int64, 
         contentComplexity: ContentComplexity, 
         hasImages: Bool, 
         hasTables: Bool, 
         textQuality: TextQuality) {
        self.pageCount = pageCount
        self.estimatedSize = estimatedSize
        self.contentComplexity = contentComplexity
        self.hasImages = hasImages
        self.hasTables = hasTables
        self.textQuality = textQuality
    }
}

/// Content complexity levels
enum ContentComplexity {
    case low
    case medium
    case high
}

/// Text quality assessment
enum TextQuality {
    case excellent
    case good
    case poor
    case scanned
}


/// System resource assessment
struct ResourceAssessment {
    let availableMemory: Int64
    let systemLoad: Double
    let memoryPressure: MemoryPressureLevel
    
    init(availableMemory: Int64, systemLoad: Double, memoryPressure: MemoryPressureLevel) {
        self.availableMemory = availableMemory
        self.systemLoad = systemLoad
        self.memoryPressure = memoryPressure
    }
}


/// Context for strategy evaluation
struct StrategyEvaluationContext {
    let documentAnalysis: StrategyDocumentAnalysis
    let resourceAssessment: ResourceAssessment
    let userPreferences: ExtractionPreferences
    
    init(documentAnalysis: StrategyDocumentAnalysis, 
         resourceAssessment: ResourceAssessment, 
         userPreferences: ExtractionPreferences) {
        self.documentAnalysis = documentAnalysis
        self.resourceAssessment = resourceAssessment
        self.userPreferences = userPreferences
    }
}
