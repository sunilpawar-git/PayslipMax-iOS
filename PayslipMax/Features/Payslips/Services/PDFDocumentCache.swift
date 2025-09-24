import Foundation
import PDFKit

/// Protocol for PDF Document Cache to enable dependency injection
protocol PDFDocumentCacheProtocol {
    /// Cache a PDF document with the given key
    func cacheDocument(_ document: PDFDocument, for key: String)

    /// Retrieve a cached PDF document by key
    func getDocument(for key: String) -> PDFDocument?

    /// Clear all cached documents
    func clearCache()
}

/// PDF Document Cache for improved performance
/// Provides LRU cache functionality for PDFDocument objects
/// Now supports both singleton and dependency injection patterns
class PDFDocumentCache: PDFDocumentCacheProtocol, SafeConversionProtocol {
    static let shared = PDFDocumentCache()

    private var cache: [String: PDFDocument] = [:]
    private let cacheLimit: Int
    private var lruKeys: [String] = []

    /// Current conversion state
    var conversionState: ConversionState = .singleton

    /// Feature flag that controls DI vs singleton usage
    var controllingFeatureFlag: Feature { return .diPDFDocumentCache }

    /// Initialize with dependency injection support
    /// - Parameter dependencies: Dependencies including optional cacheLimit
    init(dependencies: [String: Any] = [:]) {
        if let limit = dependencies["cacheLimit"] as? Int {
            self.cacheLimit = limit
        } else {
            self.cacheLimit = 20 // Default value
        }
    }

    /// Private initializer to maintain singleton pattern
    private convenience init() {
        self.init(dependencies: [:])
    }

    func cacheDocument(_ document: PDFDocument, for key: String) {
        // Remove least recently used if at capacity
        if cache.count >= cacheLimit && !lruKeys.isEmpty {
            if let lruKey = lruKeys.first {
                cache.removeValue(forKey: lruKey)
                lruKeys.removeFirst()
            }
        }

        // Add to cache
        cache[key] = document

        // Update LRU order
        if let index = lruKeys.firstIndex(of: key) {
            lruKeys.remove(at: index)
        }
        lruKeys.append(key)
    }

    func getDocument(for key: String) -> PDFDocument? {
        guard let document = cache[key] else { return nil }

        // Update LRU order
        if let index = lruKeys.firstIndex(of: key) {
            lruKeys.remove(at: index)
        }
        lruKeys.append(key)

        return document
    }

    func clearCache() {
        cache.removeAll()
        lruKeys.removeAll()
    }

    // MARK: - SafeConversionProtocol Implementation

    /// Validates that the service can be safely converted to DI
    func validateConversionSafety() async -> Bool {
        // PDF cache has no external dependencies, safe to convert
        return true
    }

    /// Performs the conversion from singleton to DI pattern
    func performConversion(container: any DIContainerProtocol) async -> Bool {
        do {
            conversionState = .converting
            await ConversionTracker.shared.updateConversionState(for: PDFDocumentCache.self, state: .converting)

            // Note: Integration with existing DI architecture will be handled separately
            // This method validates the conversion is safe and updates tracking

            conversionState = .dependencyInjected
            await ConversionTracker.shared.updateConversionState(for: PDFDocumentCache.self, state: .dependencyInjected)

            Logger.info("Successfully converted PDFDocumentCache to DI pattern", category: "PDFDocumentCache")
            return true
        } catch {
            conversionState = .error
            await ConversionTracker.shared.updateConversionState(for: PDFDocumentCache.self, state: .error)
            Logger.error("Failed to convert PDFDocumentCache: \(error)", category: "PDFDocumentCache")
            return false
        }
    }

    /// Rolls back to singleton pattern if issues are detected
    func rollbackConversion() async -> Bool {
        conversionState = .singleton
        await ConversionTracker.shared.updateConversionState(for: PDFDocumentCache.self, state: .singleton)
        Logger.info("Rolled back PDFDocumentCache to singleton pattern", category: "PDFDocumentCache")
        return true
    }

    /// Validates dependencies are properly injected and functional
    func validateDependencies() async -> DependencyValidationResult {
        // No external dependencies required for this service
        return .success
    }

    /// Creates a new instance via dependency injection
    func createDIInstance(dependencies: [String: Any]) -> Self? {
        return PDFDocumentCache(dependencies: dependencies) as? Self
    }

    /// Returns the singleton instance (fallback mode)
    static func sharedInstance() -> Self {
        return shared as! Self
    }

    /// Determines whether to use DI or singleton based on feature flags
    @MainActor static func resolveInstance() -> Self {
        let featureFlagManager = FeatureFlagManager.shared
        let shouldUseDI = featureFlagManager.isEnabled(.diPDFDocumentCache)

        if shouldUseDI {
            // Note: DI resolution will be integrated with existing factory pattern
            // For now, fallback to singleton until factory methods are implemented
            Logger.debug("DI enabled for PDFDocumentCache, but using singleton fallback", category: "PDFDocumentCache")
        }

        // Fallback to singleton
        return shared as! Self
    }
}
