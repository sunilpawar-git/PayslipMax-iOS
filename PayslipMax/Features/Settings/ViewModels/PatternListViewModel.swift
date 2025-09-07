import SwiftUI
import Combine

/// ViewModel for managing pattern items list
final class PatternListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var patternItems: [ExtractorPattern] = []
    @Published var isShowingAddPatternItemSheet = false

    // MARK: - Actions

    func addPatternItem(_ item: ExtractorPattern) {
        patternItems.append(item)
        isShowingAddPatternItemSheet = false
    }

    func removePatternItem(atOffsets indices: IndexSet) {
        patternItems.remove(atOffsets: indices)
    }

    func updatePatternItems(_ items: [ExtractorPattern]) {
        patternItems = items
    }
}
