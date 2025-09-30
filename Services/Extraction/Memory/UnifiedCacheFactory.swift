import Foundation

/// Factory for creating and configuring the unified cache system
/// Integrates with the existing DI container architecture
///
/// Phase 2C: Converted to dual-mode pattern for DI support
@MainActor
class UnifiedCacheFactory {

    /// Shared instance for singleton access (Phase 2C: Backward compatibility)
    static let shared = UnifiedCacheFactory()

    /// The unified cache manager instance
    private var _unifiedCacheManager: UnifiedCacheManager?
    private var _migrationHelper: CacheMigrationHelper?

    /// Phase 2C: Allow dependency injection initialization
    /// Default initializer for singleton usage
    private init() {}

    /// Phase 2C: Public initializer for DI pattern
    /// - Note: Created for dependency injection, same functionality as singleton
    init(enableDI: Bool = true) {
        // Same initialization as private init
    }

    /// Get or create the unified cache manager
    func getUnifiedCacheManager() -> UnifiedCacheManager {
        if let existingManager = _unifiedCacheManager {
            return existingManager
        }

        let manager = UnifiedCacheManager()
        _unifiedCacheManager = manager
        return manager
    }

    /// Get or create the migration helper
    func getMigrationHelper() -> CacheMigrationHelper {
        if let existingHelper = _migrationHelper {
            return existingHelper
        }

        let helper = CacheMigrationHelper(unifiedCacheManager: getUnifiedCacheManager())
        _migrationHelper = helper
        return helper
    }

    /// Initialize the unified cache system
    /// This should be called during app startup
    func initializeUnifiedCacheSystem() async -> Bool {
        let manager = getUnifiedCacheManager()
        let migrationHelper = getMigrationHelper()

        // Migrate existing cache systems
        migrationHelper.migrateAllCacheSystems()

        // Validate migration
        let migrationSuccessful = await migrationHelper.validateMigration()

        if migrationSuccessful {
            print("[UnifiedCacheFactory] Cache system migration completed successfully")
        } else {
            print("[UnifiedCacheFactory] Warning: Cache system migration validation failed")
        }

        return migrationSuccessful
    }

    /// Get cache statistics for monitoring
    func getCacheSystemStats() async -> [String: Any] {
        guard let manager = _unifiedCacheManager,
              let helper = _migrationHelper else {
            return ["status": "not_initialized"]
        }

        let migrationStatus = await helper.getMigrationStatus()

        return [
            "unified_cache_manager": [
                "current_pressure_level": manager.currentPressureLevel.description,
                "total_cache_size": manager.totalCacheSize,
                "cache_hit_rate": manager.cacheHitRate,
                "eviction_count": manager.evictionCount
            ],
            "migration_status": migrationStatus,
            "system_status": "operational"
        ]
    }

    /// Clear all caches - emergency memory pressure response
    func clearAllCaches() async {
        guard let manager = _unifiedCacheManager else { return }
        await manager.respondToMemoryPressure(.emergency)
    }

    /// Get cache instance for specific namespace (for backward compatibility)
    func getCacheForNamespace(_ namespace: CacheNamespace) -> (any CacheProtocol)? {
        // This method provides backward compatibility for existing code
        // that needs direct cache access

        switch namespace {
        case .pdfProcessing:
            return PDFProcessingCacheBridge()
        case .textExtraction:
            return AdaptiveCacheManagerBridge(adaptiveCache: AdaptiveCacheManager())
        case .documentAnalysis:
            return DocumentAnalysisCacheBridge()
        default:
            return nil
        }
    }
}

// MARK: - DI Container Integration
extension UnifiedCacheFactory {

    /// Create unified cache manager for DI container
    func makeUnifiedCacheManager() -> UnifiedCacheManager {
        return getUnifiedCacheManager()
    }

    /// Create migration helper for DI container
    func makeCacheMigrationHelper() -> CacheMigrationHelper {
        return getMigrationHelper()
    }

    /// Create PDF processing cache bridge for legacy support
    func makePDFProcessingCacheBridge() -> PDFProcessingCacheBridge {
        return PDFProcessingCacheBridge()
    }

    /// Create adaptive cache manager bridge for legacy support
    func makeAdaptiveCacheManagerBridge() -> AdaptiveCacheManagerBridge {
        return AdaptiveCacheManagerBridge(adaptiveCache: AdaptiveCacheManager())
    }
}

// MARK: - System Integration Helper
extension UnifiedCacheFactory {

    /// Setup unified cache system with existing memory managers
    func setupWithExistingMemoryManagers() async {
        let manager = getUnifiedCacheManager()

        // Integrate with existing memory pressure monitoring
        setupMemoryPressureIntegration(manager: manager)

        // Initialize cache migration
        _ = await initializeUnifiedCacheSystem()
    }

    private func setupMemoryPressureIntegration(manager: UnifiedCacheManager) {
        // Set up notifications to respond to system memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await manager.respondToMemoryPressure(.critical)
            }
        }

        // Set up integration with existing EnhancedMemoryManager
        // This would coordinate pressure responses across systems
        setupEnhancedMemoryManagerIntegration(manager: manager)
    }

    private func setupEnhancedMemoryManagerIntegration(manager: UnifiedCacheManager) {
        // TODO: Integrate with existing EnhancedMemoryManager
        // for coordinated memory pressure responses

        // Listen for memory pressure notifications
        NotificationCenter.default.addObserver(
            forName: .memoryPressureDetected,
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let level = userInfo["level"] as? EnhancedMemoryManager.MemoryPressureLevel {

                Task { @MainActor in
                    // Convert to unified pressure level
                    let unifiedLevel: UnifiedMemoryPressureLevel = switch level {
                    case .normal: .normal
                    case .warning: .warning
                    case .critical: .critical
                    case .emergency: .emergency
                    }

                    await manager.respondToMemoryPressure(unifiedLevel)
                }
            }
        }
    }
}

// MARK: - Memory Pressure Notification
extension Notification.Name {
    static let memoryPressureDetected = Notification.Name("memoryPressureDetected")
}
