import Foundation

/// Emergency rollback protocol for dependency injection conversions.
/// Provides immediate fallback mechanisms when DI conversions fail or cause issues.
///
/// This protocol ensures:
/// - Immediate rollback to singleton patterns
/// - State preservation during rollback
/// - Automatic health monitoring
/// - Safe error recovery
protocol EmergencyRollbackProtocol {

    // MARK: - Rollback Management

    /// Triggers immediate rollback to singleton pattern
    /// - Returns: Success status of rollback operation
    func triggerEmergencyRollback() async -> RollbackResult

    /// Checks if rollback is currently in progress
    var isRollbackInProgress: Bool { get }

    /// Checks if service is in rollback mode
    var isInRollbackMode: Bool { get }

    /// Validates rollback safety before execution
    /// - Returns: true if rollback is safe to perform
    func validateRollbackSafety() async -> Bool

    // MARK: - State Preservation

    /// Preserves current service state before rollback
    /// - Returns: Preserved state data
    func preserveCurrentState() async -> [String: Any]

    /// Restores preserved state after rollback
    /// - Parameter state: Previously preserved state
    /// - Returns: Success status of state restoration
    func restorePreservedState(_ state: [String: Any]) async -> Bool

    // MARK: - Health Monitoring

    /// Continuously monitors service health during DI usage
    func startHealthMonitoring()

    /// Stops health monitoring
    func stopHealthMonitoring()

    /// Gets current health score (0.0 to 1.0)
    var healthScore: Double { get }

    /// Threshold below which automatic rollback is triggered
    var criticalHealthThreshold: Double { get }
}

// MARK: - Supporting Types

struct RollbackResult {
    let success: Bool
    let duration: TimeInterval
    let errors: [RollbackError]
    let statePreserved: Bool
    let finalState: ConversionState

    static func success(duration: TimeInterval) -> RollbackResult {
        RollbackResult(success: true, duration: duration, errors: [], statePreserved: true, finalState: .singleton)
    }

    static func failure(errors: [RollbackError], duration: TimeInterval) -> RollbackResult {
        RollbackResult(success: false, duration: duration, errors: errors, statePreserved: false, finalState: .error)
    }
}

enum RollbackError: Error, LocalizedError {
    case statePreservationFailed(String), singletonRecreationFailed(String), dependencyCleanupFailed(String)
    case healthCheckFailed(String), timeoutExceeded(TimeInterval), concurrentRollbackDetected, criticalSystemError(String)

    var errorDescription: String? {
        switch self {
        case .statePreservationFailed(let d): return "Failed to preserve service state: \(d)"
        case .singletonRecreationFailed(let d): return "Failed to recreate singleton instance: \(d)"
        case .dependencyCleanupFailed(let d): return "Failed to clean up DI dependencies: \(d)"
        case .healthCheckFailed(let d): return "Health check failed during rollback: \(d)"
        case .timeoutExceeded(let t): return "Rollback operation timed out after \(t) seconds"
        case .concurrentRollbackDetected: return "Another rollback operation is already in progress"
        case .criticalSystemError(let d): return "Critical system error during rollback: \(d)"
        }
    }
}

// MARK: - Emergency Rollback Manager

/// Centralized manager for emergency rollback operations across all services
@MainActor
class EmergencyRollbackManager {

    /// Shared instance for coordinating rollbacks
    static let shared = EmergencyRollbackManager()

    /// Dictionary of services currently in rollback
    private var servicesInRollback: Set<String> = []

    /// Dictionary of preserved states
    private var preservedStates: [String: [String: Any]] = [:]

    /// Rollback operation queue
    private let rollbackQueue = DispatchQueue(label: "com.payslipmax.rollback", attributes: .concurrent)

    /// Maximum rollback timeout
    private let maxRollbackTimeout: TimeInterval = 30.0

    /// Health monitoring timer
    private var healthMonitoringTimer: Timer?

    private init() {
        startGlobalHealthMonitoring()
    }

    // MARK: - Global Rollback Operations

    /// Triggers rollback for a specific service type
    /// - Parameter serviceType: The type of service to rollback
    /// - Returns: Rollback result
    func triggerServiceRollback<T>(_ serviceType: T.Type) async -> RollbackResult {
        let serviceName = String(describing: serviceType)

        // Check if already in rollback
        if servicesInRollback.contains(serviceName) {
            return RollbackResult.failure(
                errors: [.concurrentRollbackDetected],
                duration: 0
            )
        }

        let startTime = Date()
        servicesInRollback.insert(serviceName)

        defer {
            servicesInRollback.remove(serviceName)
        }

        do {
            // Perform rollback operation with timeout
            let result = try await withThrowingTaskGroup(of: RollbackResult.self) { group in
                group.addTask {
                    return await self.performRollbackOperation(for: serviceName)
                }

                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(self.maxRollbackTimeout * 1_000_000_000))
                    throw RollbackError.timeoutExceeded(self.maxRollbackTimeout)
                }

                // Return first completed task (either success or timeout)
                return try await group.next()!
            }

            let duration = Date().timeIntervalSince(startTime)
            return RollbackResult(
                success: result.success,
                duration: duration,
                errors: result.errors,
                statePreserved: result.statePreserved,
                finalState: result.finalState
            )

        } catch {
            let duration = Date().timeIntervalSince(startTime)
            if let rollbackError = error as? RollbackError {
                return RollbackResult.failure(errors: [rollbackError], duration: duration)
            } else {
                return RollbackResult.failure(
                    errors: [.criticalSystemError(error.localizedDescription)],
                    duration: duration
                )
            }
        }
    }

    /// Triggers system-wide emergency rollback for all DI services
    /// - Returns: Array of rollback results for each service
    func triggerSystemWideRollback() async -> [String: RollbackResult] {
        var results: [String: RollbackResult] = [:]

        // Get all services that support rollback
        let rollbackServices = getAllRollbackCapableServices()

        // Perform rollbacks in parallel with proper coordination
        await withTaskGroup(of: (String, RollbackResult).self) { group in
            for serviceName in rollbackServices {
                group.addTask {
                    let result = await self.performRollbackOperation(for: serviceName)
                    return (serviceName, result)
                }
            }

            for await (serviceName, result) in group {
                results[serviceName] = result
            }
        }

        return results
    }

    // MARK: - Health Monitoring

    /// Starts global health monitoring for all DI services
    private func startGlobalHealthMonitoring() {
        healthMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { @MainActor in
                await self.performGlobalHealthCheck()
            }
        }
    }

    /// Performs health check on all active DI services
    private func performGlobalHealthCheck() async {
        let services = getAllActiveServices()

        for serviceName in services {
            if let healthScore = await getServiceHealthScore(serviceName),
               healthScore < 0.5 { // Critical threshold

                // Trigger automatic rollback for unhealthy service
                let result = await performRollbackOperation(for: serviceName)

                if result.success {
                    logRollbackEvent(serviceName, reason: "Automatic health-based rollback", result: result)
                } else {
                    logCriticalError(serviceName, errors: result.errors)
                }
            }
        }
    }

    // MARK: - Private Implementation

    /// Performs the actual rollback operation for a service
    private func performRollbackOperation(for serviceName: String) async -> RollbackResult {
        let startTime = Date()
        var errors: [RollbackError] = []

        // Step 1: Preserve current state
        if let currentState = await preserveServiceState(serviceName) {
            preservedStates[serviceName] = currentState
        } else {
            errors.append(.statePreservationFailed("Could not preserve state for \(serviceName)"))
        }

        // Step 2: Disable DI feature flag
        await disableDIFeatureFlag(for: serviceName)

        // Step 3: Validate singleton recreation
        let singletonValid = await validateSingletonRecreation(for: serviceName)
        if !singletonValid {
            errors.append(.singletonRecreationFailed("Singleton recreation failed for \(serviceName)"))
        }

        // Step 4: Clean up DI registrations
        await cleanupDIRegistrations(for: serviceName)

        // Step 5: Perform final health check
        if let healthScore = await getServiceHealthScore(serviceName), healthScore < 0.7 {
            errors.append(.healthCheckFailed("Post-rollback health check failed for \(serviceName)"))
        }

        let duration = Date().timeIntervalSince(startTime)
        let success = errors.isEmpty

        return RollbackResult(
            success: success,
            duration: duration,
            errors: errors,
            statePreserved: preservedStates[serviceName] != nil,
            finalState: success ? .singleton : .error
        )
    }

    // MARK: - Helper Methods (see EmergencyRollbackHelpers.swift extension)

    deinit {
        healthMonitoringTimer?.invalidate()
    }
}
