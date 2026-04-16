import Foundation

// MARK: - Private Implementation

extension EmergencyRollbackManager {

    func performRollbackOperation(for serviceName: String) async -> RollbackResult {
        let startTime = Date()
        var errors: [RollbackError] = []

        if let currentState = await preserveServiceState(serviceName) {
            preservedStates[serviceName] = currentState
        } else {
            errors.append(.statePreservationFailed("Could not preserve state for \(serviceName)"))
        }

        await disableDIFeatureFlag(for: serviceName)

        let singletonValid = await validateSingletonRecreation(for: serviceName)
        if !singletonValid {
            errors.append(.singletonRecreationFailed("Singleton recreation failed for \(serviceName)"))
        }

        await cleanupDIRegistrations(for: serviceName)

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
}
