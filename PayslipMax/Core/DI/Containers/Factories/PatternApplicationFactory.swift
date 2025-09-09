import Foundation
import PDFKit

/// Factory for pattern application components.
/// Handles pattern application strategies, validation, and pattern applier creation.
@MainActor
class PatternApplicationFactory {

    // MARK: - Dependencies

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    // MARK: - Pattern Application Components

    /// Creates pattern application strategies for handling different pattern types
    func makePatternApplicationStrategies() -> PatternApplicationStrategies {
        return PatternApplicationStrategies()
    }

    /// Creates pattern application validation for validating patterns and extracted values
    func makePatternApplicationValidation() -> PatternApplicationValidation {
        return PatternApplicationValidation()
    }

    /// Creates a pattern applier with proper dependency injection
    func makePatternApplier() -> PatternApplier {
        return PatternApplier(
            strategies: makePatternApplicationStrategies(),
            validation: makePatternApplicationValidation()
        )
    }
}
