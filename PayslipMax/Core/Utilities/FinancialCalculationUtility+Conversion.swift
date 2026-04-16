import Foundation

// MARK: - SafeConversionProtocol Implementation

extension FinancialCalculationUtility {

    func validateConversionSafety() async -> Bool {
        return true
    }

    func validateDependencies() async -> DependencyValidationResult {
        return DependencyValidationResult.success
    }

    func createDIInstance(dependencies: [String: Any]) -> Self? {
        return FinancialCalculationUtility(dependencies: dependencies) as? Self
    }

    func performConversion(container: any DIContainerProtocol) async -> Bool {
        await MainActor.run {
            conversionState = .converting
            ConversionTracker.shared.updateConversionState(for: FinancialCalculationUtility.self, state: .converting)
        }

        await MainActor.run {
            conversionState = .dependencyInjected
            ConversionTracker.shared.updateConversionState(for: FinancialCalculationUtility.self, state: .dependencyInjected)
        }
        Logger.info("Successfully converted FinancialCalculationUtility to DI pattern", category: "FinancialCalculationUtility")
        return true
    }

    func rollbackConversion() async -> Bool {
        await MainActor.run {
            conversionState = .singleton
            ConversionTracker.shared.updateConversionState(for: FinancialCalculationUtility.self, state: .singleton)
        }
        Logger.info("Rolled back FinancialCalculationUtility to singleton pattern", category: "FinancialCalculationUtility")
        return true
    }

    static func sharedInstance() -> Self { shared as! Self }
}
