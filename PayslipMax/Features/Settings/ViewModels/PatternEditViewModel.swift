import Foundation

/// ViewModel for pattern editing operations
/// Handles complex initialization and configuration of pattern editing components
/// Follows SOLID principles with single responsibility focus
@MainActor
final class PatternEditViewModel: ObservableObject {

    // MARK: - Properties

    private let container: DIContainer
    private let patternManagementViewModel: PatternManagementViewModel
    private let validationViewModel: PatternValidationViewModel
    private let listViewModel: PatternListViewModel

    // MARK: - Initialization

    @MainActor
    init(container: DIContainer) {
        self.container = container
        self.patternManagementViewModel = container.makePatternManagementViewModel()
        self.validationViewModel = container.makePatternValidationViewModel()
        self.listViewModel = container.makePatternListViewModel()
    }

    /// Convenience initializer that uses the shared DI container
    @MainActor
    convenience init() {
        self.init(container: DIContainer.shared)
    }

    /// Configure view models with existing pattern data
    /// - Parameter pattern: Optional existing pattern to edit
    func configure(with pattern: PatternDefinition?) {
        if let pattern = pattern {
            validationViewModel.updateFromPattern(pattern)
            listViewModel.updatePatternItems(pattern.patterns)
        } else {
            validationViewModel.createNewPattern()
        }
    }

    // MARK: - Accessors

    var patternManagementVM: PatternManagementViewModel {
        patternManagementViewModel
    }

    var patternValidationVM: PatternValidationViewModel {
        validationViewModel
    }

    var patternListVM: PatternListViewModel {
        listViewModel
    }

    // MARK: - Actions

    /// Save the current pattern
    func savePattern() {
        // Create the final pattern with current data
        var finalPattern = validationViewModel.currentPattern
        finalPattern.patterns = listViewModel.patternItems
        finalPattern.lastModified = Date()

        // Save the pattern
        patternManagementViewModel.savePattern(finalPattern)
    }

    /// Delete the current pattern
    /// - Parameter pattern: Pattern to delete
    func deletePattern(_ pattern: PatternDefinition) {
        patternManagementViewModel.deletePattern(pattern)
    }
}
