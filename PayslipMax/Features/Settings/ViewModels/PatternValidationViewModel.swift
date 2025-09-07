import SwiftUI
import Combine

/// ViewModel for pattern validation and form state management
final class PatternValidationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var patternName: String = ""
    @Published var patternKey: String = ""
    @Published var patternCategory: PatternCategory = .personal
    @Published var patternItems: [ExtractorPattern] = []

    // MARK: - Computed Properties

    var isValid: Bool {
        !patternName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !patternKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !patternItems.isEmpty
    }

    var currentPattern: PatternDefinition {
        PatternDefinition(
            id: UUID(),
            name: patternName,
            key: patternKey,
            category: patternCategory,
            patterns: patternItems,
            isCore: false,
            dateCreated: Date(),
            lastModified: Date(),
            userCreated: true
        )
    }

    // MARK: - Actions

    func updateFromPattern(_ pattern: PatternDefinition) {
        patternName = pattern.name
        patternKey = pattern.key
        patternCategory = pattern.category
        patternItems = pattern.patterns
    }

    func createNewPattern() {
        patternName = ""
        patternKey = ""
        patternCategory = .personal
        patternItems = []
    }
}
