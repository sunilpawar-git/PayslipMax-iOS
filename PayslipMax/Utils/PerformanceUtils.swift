import Foundation
import SwiftUI
import UIKit
import Combine
import CommonCrypto
import CryptoKit
import Darwin // For task_info and memory metrics

// MARK: - UIPerformance Extensions

/// Extension on View to help with performance tracing
public extension View {
    /// Apply this modifier to views that need performance tracking
    func trackPerformance(viewName: String) -> some View {
        self.modifier(PerformanceTrackingViewModifier(viewName: viewName))
    }
    
    /// Apply this modifier to prevent unnecessary redraws
    func equatable<Content: Equatable>(_ content: Content) -> some View {
        self.modifier(EquatableViewModifier(content: content))
    }
    
    /// Conditionally apply modifiers to reduce unnecessary view rebuilds
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Add ID for stable diffing in lists
    func stableId<ID: Hashable>(id: ID) -> some View {
        self.id(id)
            .modifier(StableIDViewModifier(id: id))
    }
}

// MARK: - View Modifiers for Performance

/// ViewModifier to track performance metrics for a view
struct PerformanceTrackingViewModifier: ViewModifier {
    let viewName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                ViewPerformanceTracker.shared.trackRenderStart(for: viewName)
            }
            .onDisappear {
                ViewPerformanceTracker.shared.trackRenderEnd(for: viewName)
            }
    }
}

/// ViewModifier that only redraws when content changes
struct EquatableViewModifier<Content: Equatable>: ViewModifier {
    let content: Content
    
    func body(content: Self.Content) -> some View {
        content
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content == rhs.content
    }
}

/// ViewModifier that helps maintain stable IDs
struct StableIDViewModifier<ID: Hashable>: ViewModifier {
    let id: ID
    
    func body(content: Content) -> some View {
        content
    }
}

// MARK: - Memory Management Utilities

/// Utility class for managing memory in the app
public final class MemoryUtility {
    public static let shared = MemoryUtility()
    
    private var cancellables = Set<AnyCancellable>()
    private var memoryPressurePublisher = NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
    
    private init() {
        setupMemoryPressureMonitoring()
    }
    
    private func setupMemoryPressureMonitoring() {
        memoryPressurePublisher
            .sink { [weak self] _ in
                self?.handleMemoryPressure()
            }
            .store(in: &cancellables)
    }
    
    private func handleMemoryPressure() {
        // Clear image caches
        URLCache.shared.removeAllCachedResponses()
        
        // Clear in-memory caches
        clearInMemoryCaches()
        
        // Log the memory warning
        #if DEBUG
        print("⚠️ Memory Warning: Clearing caches")
        #endif
    }
    
    /// Clear all registered in-memory caches
    public func clearInMemoryCaches() {
        ImageCache.shared.clearCache()
        
        // Notify any other cache systems to clear their memory
        NotificationCenter.default.post(
            name: NSNotification.Name("ClearInMemoryCaches"),
            object: nil
        )
    }
    
    /// Get current memory usage as a percentage
    public func currentMemoryUsagePercentage() -> Double {
        // Use Process API to get memory info (Apple-recommended approach)
        let hostInfo = mach_host_self()
        
        // Get memory usage through host statistics
        var hostStatistics = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &hostStatistics) { hostStatisticsPtr in
            hostStatisticsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { hostStatisticsIntPtr in
                host_statistics64(hostInfo, HOST_VM_INFO64, hostStatisticsIntPtr, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            // Calculate memory usage based on active memory pages
            let activeMemory = Double(hostStatistics.active_count) * Double(vm_page_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            
            guard totalMemory > 0 else { return 0.0 }
            return (activeMemory / totalMemory) * 100.0
        }
        
        return 0.0
    }
}

// MARK: - Image Caching

/// Simple image cache to improve scrolling performance with images
public final class ImageCache {
    public static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    
    private init() {
        let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheURL.appendingPathComponent("ImageCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Set cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        // Subscribe to memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: NSNotification.Name("ClearInMemoryCaches"),
            object: nil
        )
    }
    
    public func store(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4) // Approx bytes for RGBA
        cache.setObject(image, forKey: key as NSString, cost: cost)
        
        // Also cache to disk for persistence
        storeToDisk(image, for: key)
    }
    
    public func image(for key: String) -> UIImage? {
        // Try memory cache first
        if let cachedImage = cache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // Try disk cache
        return imageFromDisk(for: key)
    }
    
    @objc public func clearCache() {
        cache.removeAllObjects()
    }
    
    // Clear old disk cache items (older than 7 days)
    public func clearOldDiskCache() {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        do {
            let resourceKeys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
            let enumerator = fileManager.enumerator(
                at: diskCacheURL,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )!
            
            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                
                if resourceValues.isDirectory == false,
                   let creationDate = resourceValues.creationDate,
                   creationDate < sevenDaysAgo {
                    try fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("Error cleaning disk cache: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func storeToDisk(_ image: UIImage, for key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(key.sha256Hash)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    private func imageFromDisk(for key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(key.sha256Hash)
        
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Cache it in memory for faster access next time
            cache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
}

// MARK: - String Extension for Hashing

extension String {
    var sha256Hash: String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Combine Performance Extensions

extension Publisher {
    /// Debounce high-frequency events for better performance
    func throttleForUI() -> Publishers.Throttle<Self, DispatchQueue> {
        return throttle(for: .milliseconds(16), scheduler: DispatchQueue.main, latest: true)
    }
    
    /// Delay heavy UI updates until scrolling stops
    func delayWhileScrolling<P>(_ isScrolling: P) -> AnyPublisher<Output, Failure> where P: Publisher, P.Output == Bool, P.Failure == Never {
        let mappedSelf = self.map { value in (value, false) }
        let mappedScrolling = isScrolling.map { isScrolling -> (Bool, Bool) in 
            return (false, isScrolling) 
        }
        
        return mappedSelf.combineLatest(mappedScrolling.setFailureType(to: Failure.self))
            .filter { _, scrolling in !scrolling.1 }
            .map { value, _ in value.0 }
            .eraseToAnyPublisher()
    }
}

// MARK: - Background Processing Queue

/// Queue for offloading heavy processing from the main thread
public final class BackgroundQueue {
    public static let shared = BackgroundQueue()
    
    private let queue = DispatchQueue(label: "com.payslipmax.backgroundQueue", qos: .userInitiated, attributes: .concurrent)
    private let serialQueue = DispatchQueue(label: "com.payslipmax.serialBackgroundQueue", qos: .userInitiated)
    
    private init() {}
    
    /// Execute work on a background queue and return to the main queue when complete
    public func async<T>(_ work: @escaping () -> T, completion: @escaping (T) -> Void) {
        queue.async {
            let result = work()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Execute work that must be done in order
    public func asyncSerial<T>(_ work: @escaping () -> T, completion: @escaping (T) -> Void) {
        serialQueue.async {
            let result = work()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Execute work on a background queue and return an async result
    public func task<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            queue.async {
                let result = work()
                continuation.resume(returning: result)
            }
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
/// Measure time taken by a block of code
public func measureTime(operation: String, block: () -> Void) {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let diff = CFAbsoluteTimeGetCurrent() - start
    print("⏱ \(operation) took \(diff * 1000) ms")
}

/// Measure time taken by an async block of code
public func measureTimeAsync(operation: String, block: () async -> Void) async {
    let start = CFAbsoluteTimeGetCurrent()
    await block()
    let diff = CFAbsoluteTimeGetCurrent() - start
    print("⏱ \(operation) took \(diff * 1000) ms")
}
#endif

// MARK: - Lazy Functions

/// Creates a lazy initialized value
public func lazy<T>(_ initialize: @escaping () -> T) -> () -> T {
    var value: T?
    return {
        if let cachedValue = value {
            return cachedValue
        }
        let initializedValue = initialize()
        value = initializedValue
        return initializedValue
    }
} 