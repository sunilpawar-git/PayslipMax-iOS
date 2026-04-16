import Foundation

// MARK: - SafeConversionProtocol Implementation

extension UserAnalyticsService {

    func validateConversionSafety() async -> Bool {
        return true
    }

    func performConversion(container: any DIContainerProtocol) async -> Bool {
        await MainActor.run {
            conversionState = .converting
        }

        await ConversionTracker.shared.updateConversionState(for: UserAnalyticsService.self, state: .converting)

        await MainActor.run {
            conversionState = .dependencyInjected
        }

        await ConversionTracker.shared.updateConversionState(for: UserAnalyticsService.self, state: .dependencyInjected)

        Logger.info("Successfully converted UserAnalyticsService to DI pattern", category: logCategory)
        return true
    }

    func rollbackConversion() async -> Bool {
        await MainActor.run {
            conversionState = .singleton
        }
        await ConversionTracker.shared.updateConversionState(for: UserAnalyticsService.self, state: .singleton)
        Logger.info("Rolled back UserAnalyticsService to singleton pattern", category: logCategory)
        return true
    }

    func validateDependencies() async -> DependencyValidationResult { .success }
    func createDIInstance(dependencies: [String: Any]) -> Self? { UserAnalyticsService(dependencies: dependencies) as? Self }
    static func sharedInstance() -> Self { shared as! Self }
}
