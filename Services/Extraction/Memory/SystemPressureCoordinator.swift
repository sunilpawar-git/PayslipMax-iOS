import Combine
import Foundation
import UIKit

/// System-wide pressure coordinator that unifies memory pressure responses
/// Implements Phase 2 Target 2: Standardized pressure level definitions and coordination
@MainActor
class SystemPressureCoordinator: ObservableObject {

    // MARK: - Configuration

    // MARK: - Properties

    /// Current system-wide pressure level
    @Published private(set) var currentPressureLevel: UnifiedMemoryPressureLevel = .normal

    /// System memory usage
    @Published private(set) var currentMemoryUsage: UInt64 = 0

    /// Available memory percentage
    @Published private(set) var availableMemoryPercentage: Double = 1.0

    /// Registered pressure responders
    private var pressureResponders: [WeakPressureResponder] = []

    /// Monitoring timer
    private var monitoringTimer: Timer?
    private let monitoringInterval: TimeInterval = 1.0

    /// Pressure history for trend analysis
    private var pressureHistory: [PressureReading] = []
    private let maxHistorySize = 60 // 60 seconds of history

    /// Thread safety
    private let coordinationQueue = DispatchQueue(label: "system.pressure.coordinator", attributes: .concurrent)

    // MARK: - Initialization

    init() {
        setupSystemMonitoring()
        setupNotifications()
    }

    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Interface

    /// Register a pressure responder
    /// - Parameter responder: Object that responds to memory pressure changes
    func registerPressureResponder(_ responder: MemoryPressureResponder) {
        coordinationQueue.async(flags: .barrier) {
            // Remove any existing weak references that are nil
            self.pressureResponders.removeAll { $0.responder == nil }

            // Add new responder
            self.pressureResponders.append(WeakPressureResponder(responder))
        }
    }

    /// Unregister a pressure responder
    /// - Parameter responder: Object to unregister
    func unregisterPressureResponder(_ responder: MemoryPressureResponder) {
        coordinationQueue.async(flags: .barrier) {
            self.pressureResponders.removeAll {
                $0.responder == nil || ($0.responder as? AnyObject) === (responder as? AnyObject)
            }
        }
    }

    /// Manually trigger pressure response
    /// - Parameter level: Pressure level to trigger
    func triggerPressureResponse(_ level: UnifiedMemoryPressureLevel) async {
        await updatePressureLevel(level)
        await notifyPressureResponders(level)
    }

    /// Get current system pressure assessment
    func getCurrentPressureAssessment() -> PressureAssessment {
        return PressureAssessment(
            level: currentPressureLevel,
            memoryUsage: currentMemoryUsage,
            availablePercentage: availableMemoryPercentage,
            trend: calculatePressureTrend(),
            timestamp: Date()
        )
    }

    // MARK: - Memory Monitoring

    func startMonitoring() {
        stopMonitoring()

        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateSystemPressure()
            }
        }
    }

    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    private func updateSystemPressure() async {
        let currentUsage = MemoryUtils.getCurrentMemoryUsage()
        let pressureLevel = calculateStandardizedPressureLevel(for: currentUsage)
        let availablePercentage = calculateAvailableMemoryPercentage(current: currentUsage)

        // Update published properties
        currentMemoryUsage = currentUsage
        availableMemoryPercentage = availablePercentage

        // Update pressure history
        coordinationQueue.async(flags: .barrier) {
            self.addPressureReading(usage: currentUsage, level: pressureLevel)
        }

        // Check if pressure level changed
        if pressureLevel != currentPressureLevel {
            await updatePressureLevel(pressureLevel)
            await notifyPressureResponders(pressureLevel)
        }
    }

    private func calculateStandardizedPressureLevel(for usage: UInt64) -> UnifiedMemoryPressureLevel {
        return StandardizedMemoryThresholds.calculatePressureLevel(for: usage)
    }

    private func calculateAvailableMemoryPercentage(current: UInt64) -> Double {
        return PressureAnalysisUtils.calculateAvailableMemoryPercentage(current: current)
    }

    private func updatePressureLevel(_ level: UnifiedMemoryPressureLevel) async {
        currentPressureLevel = level

        // Post system-wide notification
        NotificationCenter.default.post(
            name: .systemMemoryPressureChanged,
            object: self,
            userInfo: [
                "level": level,
                "usage": currentMemoryUsage,
                "available_percentage": availableMemoryPercentage
            ]
        )
    }

    // MARK: - Pressure Response Coordination

    private func notifyPressureResponders(_ level: UnifiedMemoryPressureLevel) async {
        let responders = await coordinationQueue.sync {
            self.pressureResponders.compactMap { $0.responder }
        }

        // Notify all responders concurrently
        await withTaskGroup(of: Void.self) { group in
            for responder in responders {
                group.addTask {
                    await responder.respondToMemoryPressure(level)
                }
            }
        }
    }

    // MARK: - Pressure History and Trends

    private func addPressureReading(usage: UInt64, level: UnifiedMemoryPressureLevel) {
        let reading = PressureReading(
            timestamp: Date(),
            memoryUsage: usage,
            pressureLevel: level
        )

        pressureHistory.append(reading)

        // Keep history size manageable
        if pressureHistory.count > maxHistorySize {
            pressureHistory.removeFirst()
        }
    }

    private func calculatePressureTrend() -> PressureTrend {
        return PressureAnalysisUtils.calculateTrend(from: pressureHistory)
    }

    // MARK: - System Integration

    private func setupSystemMonitoring() {
        startMonitoring()
    }

    private func setupNotifications() {
        // Listen to system memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.triggerPressureResponse(.critical)
            }
        }

        // Listen to app state changes
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Reduce monitoring frequency in background
            self?.stopMonitoring()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Resume normal monitoring
            self?.startMonitoring()
        }
    }
}

// MARK: - Legacy Memory Manager Bridge
extension SystemPressureCoordinator {

    /// Convert legacy pressure levels to unified levels
    static func convertLegacyPressureLevel(_ legacyLevel: Any) -> UnifiedMemoryPressureLevel {
        return LegacyPressureConverter.convertAny(legacyLevel)
    }

    /// Get standardized thresholds for external systems
    static func getStandardizedThresholds() -> (normal: UInt64, warning: UInt64, critical: UInt64, emergency: UInt64) {
        return StandardizedMemoryThresholds.thresholds
    }
}
