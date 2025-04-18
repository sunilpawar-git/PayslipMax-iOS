import SwiftUI
import Combine

/// Provides detailed performance tracking for SwiftUI views
class ViewPerformanceTracker: ObservableObject {
    // MARK: - Published Properties
    
    /// The complete render history for each view
    @Published private(set) var renderHistory: [String: [RenderEvent]] = [:]
    
    /// Views currently being tracked
    @Published private(set) var trackedViews: Set<String> = []
    
    // MARK: - Private Properties
    
    /// In-memory storage of view rendering metrics
    private var viewMetrics: [String: ViewMetrics] = [:]
    
    /// Timer for monitoring
    private var monitorTimer: AnyCancellable?
    
    /// Singleton instance
    static let shared = ViewPerformanceTracker()
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Public API
    
    /// Tracks the start of a view's render cycle
    /// - Parameter viewName: The name of the view
    func trackRenderStart(for viewName: String) {
        trackedViews.insert(viewName)
        
        var metrics = viewMetrics[viewName] ?? ViewMetrics(viewName: viewName)
        metrics.lastRenderStartTime = CACurrentMediaTime()
        viewMetrics[viewName] = metrics
    }
    
    /// Tracks the completion of a view's render cycle
    /// - Parameter viewName: The name of the view
    func trackRenderEnd(for viewName: String) {
        guard var metrics = viewMetrics[viewName],
              let startTime = metrics.lastRenderStartTime else {
            return
        }
        
        let endTime = CACurrentMediaTime()
        let renderTime = endTime - startTime
        
        metrics.lastRenderStartTime = nil
        metrics.totalRenderCount += 1
        metrics.totalRenderTime += renderTime
        metrics.lastRenderTime = renderTime
        
        if metrics.minRenderTime == 0 || renderTime < metrics.minRenderTime {
            metrics.minRenderTime = renderTime
        }
        
        if renderTime > metrics.maxRenderTime {
            metrics.maxRenderTime = renderTime
        }
        
        let event = RenderEvent(
            timestamp: endTime,
            duration: renderTime,
            memoryUsage: PerformanceMetrics.shared.memoryUsage
        )
        
        renderHistory[viewName, default: []].append(event)
        
        // Keep history limited to avoid memory issues
        if renderHistory[viewName]?.count ?? 0 > 100 {
            renderHistory[viewName]?.removeFirst()
        }
        
        viewMetrics[viewName] = metrics
    }
    
    /// Gets metrics for a specific view
    /// - Parameter viewName: The name of the view
    /// - Returns: View metrics
    func metricsForView(_ viewName: String) -> ViewMetrics {
        return viewMetrics[viewName] ?? ViewMetrics(viewName: viewName)
    }
    
    /// Reset tracking for all views
    func resetAllTracking() {
        viewMetrics.removeAll()
        renderHistory.removeAll()
        trackedViews.removeAll()
    }
    
    /// Generates a performance report for all tracked views
    /// - Returns: A formatted report string
    func generateReport() -> String {
        let sortedMetrics = viewMetrics.values.sorted {
            $0.totalRenderTime > $1.totalRenderTime
        }
        
        var report = "View Performance Report\n"
        report += "======================\n\n"
        
        for metrics in sortedMetrics {
            report += "View: \(metrics.viewName)\n"
            report += "  Render Count: \(metrics.totalRenderCount)\n"
            
            if metrics.totalRenderCount > 0 {
                let avgTime = metrics.totalRenderTime / Double(metrics.totalRenderCount)
                report += "  Avg Render Time: \(String(format: "%.2f", avgTime * 1000)) ms\n"
                report += "  Min Render Time: \(String(format: "%.2f", metrics.minRenderTime * 1000)) ms\n"
                report += "  Max Render Time: \(String(format: "%.2f", metrics.maxRenderTime * 1000)) ms\n"
                
                if let lastRenderTime = metrics.lastRenderTime {
                    report += "  Last Render Time: \(String(format: "%.2f", lastRenderTime * 1000)) ms\n"
                }
            }
            
            report += "\n"
        }
        
        return report
    }
    
    /// Starts periodic monitoring
    private func startMonitoring() {
        monitorTimer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForStuckRenders()
            }
    }
    
    /// Checks for views that might be stuck in rendering
    private func checkForStuckRenders() {
        let currentTime = CACurrentMediaTime()
        
        for (viewName, metrics) in viewMetrics {
            if let startTime = metrics.lastRenderStartTime {
                let elapsedTime = currentTime - startTime
                
                // If rendering takes more than 1 second, it might be stuck
                if elapsedTime > 1.0 {
                    print("⚠️ Warning: View '\(viewName)' might be stuck in rendering for \(String(format: "%.2f", elapsedTime)) seconds")
                }
            }
        }
    }
}

// MARK: - Data Models

/// Stores metrics for a specific view
struct ViewMetrics {
    /// Name of the view
    let viewName: String
    
    /// Total number of renders
    var totalRenderCount: Int = 0
    
    /// Total time spent rendering (in seconds)
    var totalRenderTime: TimeInterval = 0
    
    /// Time of the last render start (nil if not currently rendering)
    var lastRenderStartTime: TimeInterval? = nil
    
    /// Duration of the last render (in seconds)
    var lastRenderTime: TimeInterval? = nil
    
    /// Minimum render time observed (in seconds)
    var minRenderTime: TimeInterval = 0
    
    /// Maximum render time observed (in seconds)
    var maxRenderTime: TimeInterval = 0
}

/// Represents a single view render event
struct RenderEvent {
    /// When the event occurred
    let timestamp: TimeInterval
    
    /// How long the render took (in seconds)
    let duration: TimeInterval
    
    /// Memory usage at the time of the event
    let memoryUsage: UInt64
}

// MARK: - View Extension for Performance Tracking

extension View {
    /// Tracks detailed performance metrics for this view
    /// - Parameter name: Name of the view to track
    /// - Returns: A modified view with performance tracking
    func trackPerformance(name: String) -> some View {
        return self
            .modifier(ViewPerformanceTrackerModifier(viewName: name))
    }
}

/// Modifier that tracks view performance
struct ViewPerformanceTrackerModifier: ViewModifier {
    let viewName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                ViewPerformanceTracker.shared.trackRenderStart(for: viewName)
            }
            .onDisappear {
                ViewPerformanceTracker.shared.trackRenderEnd(for: viewName)
            }
            .onChange(of: UUID()) { _, _ in
                // This will never actually trigger but forces SwiftUI to re-evaluate
                // the view, which is needed for tracking
            }
    }
} 