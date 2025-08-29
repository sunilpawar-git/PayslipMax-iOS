import Foundation

/// Feature flags for LiteRT AI integration with gradual rollout support
public class LiteRTFeatureFlags: ObservableObject {

    // MARK: - Singleton

    public static let shared = LiteRTFeatureFlags()

    private init() {
        loadConfiguration()
        setupProductionConfiguration()
    }

    // MARK: - Production Configuration

    /// Production deployment environment
    public enum ProductionEnvironment: String, CaseIterable {
        case development = "Development"
        case staging = "Staging"
        case production = "Production"
    }

    /// Feature flag enumeration for programmatic access
    public enum FeatureFlag: String, CaseIterable {
        case liteRTService = "enableLiteRTService"
        case tableStructureDetection = "enableTableStructureDetection"
        case pcdaOptimization = "enablePCDAOptimization"
        case hybridProcessing = "enableHybridProcessing"
        case smartFormatDetection = "enableSmartFormatDetection"
        case aiParserSelection = "enableAIParserSelection"
        case financialIntelligence = "enableFinancialIntelligence"
        case militaryCodeRecognition = "enableMilitaryCodeRecognition"
        case adaptiveLearning = "enableAdaptiveLearning"
        case personalization = "enablePersonalization"
        case predictiveAnalysis = "enablePredictiveAnalysis"
        case anomalyDetection = "enableAnomalyDetection"
        case performanceMonitoring = "enablePerformanceMonitoring"
        case fallbackMechanism = "enableFallbackMechanism"
        case memoryOptimization = "enableMemoryOptimization"
        case debugLogging = "enableDebugLogging"
    }

    /// Current production environment
    @Published public private(set) var currentEnvironment: ProductionEnvironment = .development

    /// Production rollout percentage (0-100)
    @Published public private(set) var rolloutPercentage: Int = 0

    /// Production monitoring enabled
    @Published public private(set) var productionMonitoringEnabled = false

    /// Model update mechanism enabled
    @Published public private(set) var modelUpdateEnabled = false
    
    // MARK: - Feature Flags
    
    /// Phase 1 Features
    @Published public private(set) var enableLiteRTService = true  // Enabled for mock testing
    @Published public private(set) var enableTableStructureDetection = true  // Enabled for mock testing
    @Published public private(set) var enablePCDAOptimization = true  // Enabled for mock testing
    @Published public private(set) var enableHybridProcessing = true  // Enabled for mock testing
    
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

    // MARK: - Production Configuration Methods

    /// Set up production configuration based on environment
    private func setupProductionConfiguration() {
        #if DEBUG
        currentEnvironment = .development
        rolloutPercentage = 0
        productionMonitoringEnabled = false
        modelUpdateEnabled = false
        #elseif STAGING
        currentEnvironment = .staging
        rolloutPercentage = 25
        productionMonitoringEnabled = true
        modelUpdateEnabled = true
        #else
        currentEnvironment = .production
        rolloutPercentage = 100
        productionMonitoringEnabled = true
        modelUpdateEnabled = true
        #endif

        applyRolloutConfiguration()
        print("[LiteRTFeatureFlags] Production configuration loaded: \(currentEnvironment.rawValue), Rollout: \(rolloutPercentage)%")
    }

    /// Update production rollout percentage
    public func setRolloutPercentage(_ percentage: Int) {
        guard (0...100).contains(percentage) else {
            print("[LiteRTFeatureFlags] Invalid rollout percentage: \(percentage)")
            return
        }

        rolloutPercentage = percentage
        applyRolloutConfiguration()
        saveConfiguration()
        print("[LiteRTFeatureFlags] Rollout percentage updated to: \(percentage)%")
    }

    /// Apply rollout configuration based on percentage
    private func applyRolloutConfiguration() {
        // Phase rollout logic based on percentage
        switch rolloutPercentage {
        case 0:
            // 0% - All features disabled
            disableAllFeatures()
        case 1...10:
            // 1-10% - Phase 1 Alpha
            enableLiteRTService = true
            enableTableStructureDetection = true
            enablePerformanceMonitoring = true
        case 11...25:
            // 11-25% - Phase 1 Beta
            enablePhase1Features()
        case 26...50:
            // 26-50% - Phase 2 features
            enablePhase1Features()
            enableSmartFormatDetection = true
            enableAIParserSelection = true
        case 51...75:
            // 51-75% - Phase 3 features
            enablePhase1Features()
            enableSmartFormatDetection = true
            enableAIParserSelection = true
            enableFinancialIntelligence = true
            enableMilitaryCodeRecognition = true
        case 76...100:
            // 76-100% - Full production rollout
            enablePhase1Features()
            enableSmartFormatDetection = true
            enableAIParserSelection = true
            enableFinancialIntelligence = true
            enableMilitaryCodeRecognition = true
            enableAdaptiveLearning = true
            enablePersonalization = true
            enablePredictiveAnalysis = true
            enableAnomalyDetection = true
        default:
            break
        }

        // Always enable safety features in production
        enableFallbackMechanism = true
        enableMemoryOptimization = true
        enablePerformanceMonitoring = productionMonitoringEnabled
    }

    /// Configure for specific production environment
    public func configureForEnvironment(_ environment: ProductionEnvironment, rolloutPercentage: Int = 100) {
        currentEnvironment = environment
        self.rolloutPercentage = rolloutPercentage
        productionMonitoringEnabled = (environment != .development)
        modelUpdateEnabled = (environment != .development)

        applyRolloutConfiguration()
        saveConfiguration()
        print("[LiteRTFeatureFlags] Configured for \(environment.rawValue) environment with \(rolloutPercentage)% rollout")
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

        // Load production configuration
        if let envString = defaults.string(forKey: "LiteRT_ProductionEnvironment"),
           let environment = ProductionEnvironment(rawValue: envString) {
            currentEnvironment = environment
        }
        rolloutPercentage = defaults.integer(forKey: "LiteRT_RolloutPercentage")
        productionMonitoringEnabled = defaults.bool(forKey: "LiteRT_ProductionMonitoringEnabled")
        modelUpdateEnabled = defaults.bool(forKey: "LiteRT_ModelUpdateEnabled")

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

        // Save production configuration
        defaults.set(currentEnvironment.rawValue, forKey: "LiteRT_ProductionEnvironment")
        defaults.set(rolloutPercentage, forKey: "LiteRT_RolloutPercentage")
        defaults.set(productionMonitoringEnabled, forKey: "LiteRT_ProductionMonitoringEnabled")
        defaults.set(modelUpdateEnabled, forKey: "LiteRT_ModelUpdateEnabled")

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

    /// Get production configuration for diagnostics
    public func getProductionStatus() -> [String: Any] {
        return [
            "Environment": currentEnvironment.rawValue,
            "RolloutPercentage": rolloutPercentage,
            "ProductionMonitoring": productionMonitoringEnabled,
            "ModelUpdateEnabled": modelUpdateEnabled,
            "Phase1Enabled": isPhase1Enabled,
            "LiteRTEnabled": isLiteRTEnabled
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
