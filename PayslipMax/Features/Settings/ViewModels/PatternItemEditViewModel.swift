import SwiftUI
import Combine

/// ViewModel for pattern item editing
final class PatternItemEditViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var patternType: ExtractorPatternType = .regex
    @Published var regexPattern = ""
    @Published var keyword = ""
    @Published var contextBefore = ""
    @Published var contextAfter = ""
    @Published var lineOffset = 0
    @Published var startPosition: Int?
    @Published var endPosition: Int?
    @Published var priority = 10
    @Published var selectedPreprocessing: Set<ExtractorPattern.PreprocessingStep> = []
    @Published var selectedPostprocessing: Set<ExtractorPattern.PostprocessingStep> = []

    // MARK: - Computed Properties

    var isValid: Bool {
        switch patternType {
        case .regex:
            return !regexPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .keyword:
            return !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .positionBased:
            return true
        }
    }

    var extractorPattern: ExtractorPattern {
        switch patternType {
        case .regex:
            return .regex(
                pattern: regexPattern,
                preprocessing: Array(selectedPreprocessing),
                postprocessing: Array(selectedPostprocessing),
                priority: priority
            )
        case .keyword:
            return .keyword(
                keyword: keyword,
                contextBefore: contextBefore.isEmpty ? nil : contextBefore,
                contextAfter: contextAfter.isEmpty ? nil : contextAfter,
                preprocessing: Array(selectedPreprocessing),
                postprocessing: Array(selectedPostprocessing),
                priority: priority
            )
        case .positionBased:
            return .positionBased(
                lineOffset: lineOffset,
                startPosition: startPosition,
                endPosition: endPosition,
                preprocessing: Array(selectedPreprocessing),
                postprocessing: Array(selectedPostprocessing),
                priority: priority
            )
        }
    }

    // MARK: - Actions

    func reset() {
        patternType = .regex
        regexPattern = ""
        keyword = ""
        contextBefore = ""
        contextAfter = ""
        lineOffset = 0
        startPosition = nil
        endPosition = nil
        priority = 10
        selectedPreprocessing = []
        selectedPostprocessing = []
    }
}

