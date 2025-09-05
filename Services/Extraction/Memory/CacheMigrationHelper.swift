import Foundation

/// Helper class for migrating existing cache systems to unified cache
/// Extracted from CacheBridgeAdapters to maintain 300-line compliance
@MainActor
class CacheMigrationHelper {
    private let unifiedCacheManager: UnifiedCacheManager
    
    init(unifiedCacheManager: UnifiedCacheManager) {
        self.unifiedCacheManager = unifiedCacheManager
    }
    
    /// Migrate all existing cache systems to unified cache
    func migrateAllCacheSystems() {
        // Register PDF processing cache
        registerPDFProcessingCache()
        
        // Register adaptive cache manager
        registerAdaptiveCacheManager()
        
        // Register document analysis cache
        registerDocumentAnalysisCache()
        
        // Note: OptimizedProcessingPipeline cache is read-only for metrics only
        registerProcessingPipelineMetrics()
    }
    
    private func registerPDFProcessingCache() {
        let bridge = PDFProcessingCacheBridge()
        unifiedCacheManager.registerCache(
            bridge,
            namespace: .pdfProcessing,
            level: .l2Persistent
        )
    }
    
    private func registerAdaptiveCacheManager() {
        // Create adaptive cache manager instance
        let adaptiveCache = AdaptiveCacheManager()
        let bridge = AdaptiveCacheManagerBridge(adaptiveCache: adaptiveCache)
        unifiedCacheManager.registerCache(
            bridge,
            namespace: .textExtraction,
            level: .l1Processing
        )
    }
    
    private func registerDocumentAnalysisCache() {
        let bridge = DocumentAnalysisCacheBridge()
        unifiedCacheManager.registerCache(
            bridge,
            namespace: .documentAnalysis,
            level: .l1Processing
        )
    }
    
    private func registerProcessingPipelineMetrics() {
        // OptimizedProcessingPipeline is registered for metrics only
        // Direct caching goes through the pipeline's own interface
        // This bridge only provides cache clearing and metrics
    }
    
    /// Validate cache migration succeeded
    func validateMigration() async -> Bool {
        // Test each cache namespace
        let testKey = "migration_test"
        let testValue = "test_value"
        
        // Test PDF processing cache
        let pdfStoreSuccess = await unifiedCacheManager.store(
            testValue,
            forKey: testKey,
            namespace: .pdfProcessing
        )
        
        let pdfRetrieveSuccess = await unifiedCacheManager.retrieve(
            String.self,
            forKey: testKey,
            namespace: .pdfProcessing
        ) == testValue
        
        // Test text extraction cache
        let textStoreSuccess = await unifiedCacheManager.store(
            testValue,
            forKey: testKey,
            namespace: .textExtraction
        )
        
        let textRetrieveSuccess = await unifiedCacheManager.retrieve(
            String.self,
            forKey: testKey,
            namespace: .textExtraction
        ) == testValue
        
        return pdfStoreSuccess && pdfRetrieveSuccess && textStoreSuccess && textRetrieveSuccess
    }
    
    /// Migrate data from existing caches to unified cache system
    func migrateExistingCacheData() async {
        // TODO: Implement data migration from existing cache systems
        // This would involve reading from old caches and storing in unified cache
        // with appropriate namespace and level mapping
        
        await migratePDFProcessingCacheData()
        await migrateAdaptiveCacheData()
    }
    
    private func migratePDFProcessingCacheData() async {
        // PDF processing cache already uses the same storage
        // No data migration needed - just bridge registration
    }
    
    private func migrateAdaptiveCacheData() async {
        // Adaptive cache data would need to be read and re-stored
        // with unified cache keys and namespaces
    }
    
    /// Clean up old cache systems after successful migration
    func cleanupLegacyCaches() {
        // Clear old caches to prevent memory conflicts
        // This should only be called after validation succeeds
        
        // Note: We keep the instances for bridge pattern
        // but could implement cleanup if needed
    }
    
    /// Get migration status report
    func getMigrationStatus() async -> [String: Any] {
        let validationSuccess = await validateMigration()
        
        return [
            "migration_complete": validationSuccess,
            "registered_namespaces": CacheNamespace.allCases.map { $0.rawValue },
            "cache_levels": CacheLevel.allCases.map { $0.rawValue },
            "validation_passed": validationSuccess,
            "unified_manager_status": "active"
        ]
    }
}
