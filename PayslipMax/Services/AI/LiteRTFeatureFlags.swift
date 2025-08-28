import Foundation

/// Feature flags for LiteRT AI integration with gradual rollout support
public class LiteRTFeatureFlags {
    
    // MARK: - Singleton
    
    public static let shared = LiteRTFeatureFlags()
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Feature Flags
    
    /// Phase 1 Features
    @Published public private(set) var enableLiteRTService = false
    @Published public private(set) var enableTableStructureDetection = false
    @Published public private(set) var enablePCDAOptimization = false
    @Published public private(set) var enableHybridProcessing = false
    
    /// Phase 2 Features (Future)
    @Published public private(set) var enableSmartFormatDetection = false
    @Published public private(set) var enableAIParserSelection = false
    
    /// Phase 3 Features (Future)
    @Published public private(set) var enableFinancialIntelligence = false
    @Published public private(set) var enableMilitaryCodeRecognition = false
    
    /// Phase 4 Features (Future)
    @Published public private(set) var enableAdaptiveLearning = false
    @Published public private(set) var enablePersonalization = false
    
    /// Phase 5 Features (Future)
    @Published public private(set) var enablePredictiveAnalysis = false
    @Published public private(set) var enableAnomalyDetection = false
    
    // MARK: - Performance & Safety Flags
    
    @Published public private(set) var enablePerformanceMonitoring = true
    @Published public private(set) var enableFallbackMechanism = true
    @Published public private(set) var enableMemoryOptimization = true
    @Published public private(set) var enableDebugLogging = false
    
    // MARK: - Configuration Methods
    
    /// Enable Phase 1 features for initial rollout
    public func enablePhase1Features() {
        print("[LiteRTFeatureFlags] Enabling Phase 1 features")
        enableLiteRTService = true
        enableTableStructureDetection = true
        enablePCDAOptimization = true
        enableHybridProcessing = true
        saveConfiguration()
    }
    
    /// Disable all LiteRT features (emergency rollback)
    public func disableAllFeatures() {
        print("[LiteRTFeatureFlags] Disabling all LiteRT features")
        enableLiteRTService = false
        enableTableStructureDetection = false
        enablePCDAOptimization = false
        enableHybridProcessing = false
        enableSmartFormatDetection = false
        enableAIParserSelection = false
        enableFinancialIntelligence = false
        enableMilitaryCodeRecognition = false
        enableAdaptiveLearning = false
        enablePersonalization = false
        enablePredictiveAnalysis = false
        enableAnomalyDetection = false
        saveConfiguration()
    }
    
    /// Enable debug mode for development
    public func enableDebugMode() {
        enableDebugLogging = true
        enablePerformanceMonitoring = true
        saveConfiguration()
    }
    
    /// Check if any LiteRT features are enabled
    public var isLiteRTEnabled: Bool {
        return enableLiteRTService || enableTableStructureDetection || enablePCDAOptimization
    }
    
    /// Check if Phase 1 is fully enabled
    public var isPhase1Enabled: Bool {
        return enableLiteRTService && enableTableStructureDetection && enablePCDAOptimization && enableHybridProcessing
    }
    
    // MARK: - Dynamic Configuration
    
    /// Update individual feature flag
    public func setFeatureFlag(_ flag: FeatureFlag, enabled: Bool) {
        switch flag {
        case .liteRTService:
            enableLiteRTService = enabled
        case .tableStructureDetection:
            enableTableStructureDetection = enabled
        case .pcdaOptimization:
            enablePCDAOptimization = enabled
        case .hybridProcessing:
            enableHybridProcessing = enabled
        case .smartFormatDetection:
            enableSmartFormatDetection = enabled
        case .aiParserSelection:
            enableAIParserSelection = enabled
        case .financialIntelligence:
            enableFinancialIntelligence = enabled
        case .militaryCodeRecognition:
            enableMilitaryCodeRecognition = enabled
        case .adaptiveLearning:
            enableAdaptiveLearning = enabled
        case .personalization:
            enablePersonalization = enabled
        case .predictiveAnalysis:
            enablePredictiveAnalysis = enabled
        case .anomalyDetection:
            enableAnomalyDetection = enabled
        case .performanceMonitoring:
            enablePerformanceMonitoring = enabled
        case .fallbackMechanism:
            enableFallbackMechanism = enabled
        case .memoryOptimization:
            enableMemoryOptimization = enabled
        case .debugLogging:
            enableDebugLogging = enabled
        }
        
        saveConfiguration()
        print("[LiteRTFeatureFlags] Updated \(flag.rawValue): \(enabled)")
    }
    
    // MARK: - Persistence
    
    private func loadConfiguration() {
        let defaults = UserDefaults.standard
        
        // Load Phase 1 flags (default disabled for safety)
        enableLiteRTService = defaults.bool(forKey: "LiteRT_EnableService")
        enableTableStructureDetection = defaults.bool(forKey: "LiteRT_EnableTableDetection")
        enablePCDAOptimization = defaults.bool(forKey: "LiteRT_EnablePCDAOptimization")
        enableHybridProcessing = defaults.bool(forKey: "LiteRT_EnableHybridProcessing")
        
        // Load future phase flags
        enableSmartFormatDetection = defaults.bool(forKey: "LiteRT_EnableSmartFormatDetection")
        enableAIParserSelection = defaults.bool(forKey: "LiteRT_EnableAIParserSelection")
        enableFinancialIntelligence = defaults.bool(forKey: "LiteRT_EnableFinancialIntelligence")
        enableMilitaryCodeRecognition = defaults.bool(forKey: "LiteRT_EnableMilitaryCodeRecognition")
        enableAdaptiveLearning = defaults.bool(forKey: "LiteRT_EnableAdaptiveLearning")
        enablePersonalization = defaults.bool(forKey: "LiteRT_EnablePersonalization")
        enablePredictiveAnalysis = defaults.bool(forKey: "LiteRT_EnablePredictiveAnalysis")
        enableAnomalyDetection = defaults.bool(forKey: "LiteRT_EnableAnomalyDetection")
        
        // Load performance flags (default enabled for safety)
        enablePerformanceMonitoring = defaults.object(forKey: "LiteRT_EnablePerformanceMonitoring") as? Bool ?? true
        enableFallbackMechanism = defaults.object(forKey: "LiteRT_EnableFallbackMechanism") as? Bool ?? true
        enableMemoryOptimization = defaults.object(forKey: "LiteRT_EnableMemoryOptimization") as? Bool ?? true
        enableDebugLogging = defaults.bool(forKey: "LiteRT_EnableDebugLogging")
        
        print("[LiteRTFeatureFlags] Configuration loaded - LiteRT enabled: \(isLiteRTEnabled)")
    }
    
    private func saveConfiguration() {
        let defaults = UserDefaults.standard
        
        // Save Phase 1 flags
        defaults.set(enableLiteRTService, forKey: "LiteRT_EnableService")
        defaults.set(enableTableStructureDetection, forKey: "LiteRT_EnableTableDetection")
        defaults.set(enablePCDAOptimization, forKey: "LiteRT_EnablePCDAOptimization")
        defaults.set(enableHybridProcessing, forKey: "LiteRT_EnableHybridProcessing")
        
        // Save future phase flags
        defaults.set(enableSmartFormatDetection, forKey: "LiteRT_EnableSmartFormatDetection")
        defaults.set(enableAIParserSelection, forKey: "LiteRT_EnableAIParserSelection")
        defaults.set(enableFinancialIntelligence, forKey: "LiteRT_EnableFinancialIntelligence")
        defaults.set(enableMilitaryCodeRecognition, forKey: "LiteRT_EnableMilitaryCodeRecognition")
        defaults.set(enableAdaptiveLearning, forKey: "LiteRT_EnableAdaptiveLearning")
        defaults.set(enablePersonalization, forKey: "LiteRT_EnablePersonalization")
        defaults.set(enablePredictiveAnalysis, forKey: "LiteRT_EnablePredictiveAnalysis")
        defaults.set(enableAnomalyDetection, forKey: "LiteRT_EnableAnomalyDetection")
        
        // Save performance flags
        defaults.set(enablePerformanceMonitoring, forKey: "LiteRT_EnablePerformanceMonitoring")
        defaults.set(enableFallbackMechanism, forKey: "LiteRT_EnableFallbackMechanism")
        defaults.set(enableMemoryOptimization, forKey: "LiteRT_EnableMemoryOptimization")
        defaults.set(enableDebugLogging, forKey: "LiteRT_EnableDebugLogging")
        
        defaults.synchronize()
    }
    
    // MARK: - A/B Testing Support
    
    /// Enable features for A/B testing group
    public func enableForTestGroup(_ group: TestGroup) {
        switch group {
        case .control:
            disableAllFeatures()
            
        case .phase1Alpha:
            enableLiteRTService = true
            enableTableStructureDetection = true
            
        case .phase1Beta:
            enablePhase1Features()
            
        case .phase1Full:
            enablePhase1Features()
            enableDebugMode()
        }
        
        saveConfiguration()
        print("[LiteRTFeatureFlags] Configured for test group: \(group.rawValue)")
    }
    
    // MARK: - Feature Status Reporting
    
    /// Get current feature status for diagnostics
    public func getFeatureStatus() -> [String: Bool] {
        return [
            "LiteRTService": enableLiteRTService,
            "TableStructureDetection": enableTableStructureDetection,
            "PCDAOptimization": enablePCDAOptimization,
            "HybridProcessing": enableHybridProcessing,
            "SmartFormatDetection": enableSmartFormatDetection,
            "AIParserSelection": enableAIParserSelection,
            "FinancialIntelligence": enableFinancialIntelligence,
            "MilitaryCodeRecognition": enableMilitaryCodeRecognition,
            "AdaptiveLearning": enableAdaptiveLearning,
            "Personalization": enablePersonalization,
            "PredictiveAnalysis": enablePredictiveAnalysis,
            "AnomalyDetection": enableAnomalyDetection,
            "PerformanceMonitoring": enablePerformanceMonitoring,
            "FallbackMechanism": enableFallbackMechanism,
            "MemoryOptimization": enableMemoryOptimization,
            "DebugLogging": enableDebugLogging
        ]
    }
}

// MARK: - Supporting Types

/// Individual feature flags
public enum FeatureFlag: String, CaseIterable {
    case liteRTService = "LiteRTService"
    case tableStructureDetection = "TableStructureDetection"
    case pcdaOptimization = "PCDAOptimization"
    case hybridProcessing = "HybridProcessing"
    case smartFormatDetection = "SmartFormatDetection"
    case aiParserSelection = "AIParserSelection"
    case financialIntelligence = "FinancialIntelligence"
    case militaryCodeRecognition = "MilitaryCodeRecognition"
    case adaptiveLearning = "AdaptiveLearning"
    case personalization = "Personalization"
    case predictiveAnalysis = "PredictiveAnalysis"
    case anomalyDetection = "AnomalyDetection"
    case performanceMonitoring = "PerformanceMonitoring"
    case fallbackMechanism = "FallbackMechanism"
    case memoryOptimization = "MemoryOptimization"
    case debugLogging = "DebugLogging"
}

/// A/B testing groups
public enum TestGroup: String, CaseIterable {
    case control = "Control"
    case phase1Alpha = "Phase1Alpha"
    case phase1Beta = "Phase1Beta"
    case phase1Full = "Phase1Full"
}

// MARK: - Extensions

extension LiteRTFeatureFlags {
    
    /// Convenience method to check if a specific feature is enabled
    public func isFeatureEnabled(_ feature: FeatureFlag) -> Bool {
        switch feature {
        case .liteRTService: return enableLiteRTService
        case .tableStructureDetection: return enableTableStructureDetection
        case .pcdaOptimization: return enablePCDAOptimization
        case .hybridProcessing: return enableHybridProcessing
        case .smartFormatDetection: return enableSmartFormatDetection
        case .aiParserSelection: return enableAIParserSelection
        case .financialIntelligence: return enableFinancialIntelligence
        case .militaryCodeRecognition: return enableMilitaryCodeRecognition
        case .adaptiveLearning: return enableAdaptiveLearning
        case .personalization: return enablePersonalization
        case .predictiveAnalysis: return enablePredictiveAnalysis
        case .anomalyDetection: return enableAnomalyDetection
        case .performanceMonitoring: return enablePerformanceMonitoring
        case .fallbackMechanism: return enableFallbackMechanism
        case .memoryOptimization: return enableMemoryOptimization
        case .debugLogging: return enableDebugLogging
        }
    }
}
