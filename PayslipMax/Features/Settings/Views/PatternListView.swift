import SwiftUI

/// View component for managing pattern items list
struct PatternListView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: PatternListViewModel
    @Binding var isShowingTestPatternView: Bool
    var pattern: PatternDefinition

    // MARK: - Body

    var body: some View {
        Section {
            ForEach(viewModel.patternItems.indices, id: \.self) { index in
                PatternItemRow(pattern: $viewModel.patternItems[index])
            }
            .onDelete { indices in
                viewModel.removePatternItem(atOffsets: indices)
            }

            Button {
                viewModel.isShowingAddPatternItemSheet = true
            } label: {
                Label("Add Pattern Item", systemImage: "plus")
            }
        } header: {
            Text("Pattern Items")
        } footer: {
            Text("Pattern items define how to extract values from PDF text. Multiple items provide fallbacks if the primary patterns don't match.")
        }

        // Test pattern section
        if !viewModel.patternItems.isEmpty {
            Section {
                Button {
                    isShowingTestPatternView = true
                } label: {
                    Label("Test Pattern", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.patternItems.isEmpty)
            } footer: {
                Text("Test how this pattern extracts data from a real PDF document.")
            }
        }
    }
}

// MARK: - Preview

struct PatternListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = PatternListViewModel()
        viewModel.patternItems = [
            .regex(pattern: "\\$\\d+\\.\\d{2}", preprocessing: [], postprocessing: [.formatAsCurrency], priority: 10)
        ]

        return Form {
            PatternListView(
                viewModel: viewModel,
                isShowingTestPatternView: .constant(false),
                pattern: PatternDefinition(
                    id: UUID(),
                    name: "Sample Pattern",
                    key: "sample",
                    category: .personal,
                    patterns: [],
                    isCore: false,
                    dateCreated: Date(),
                    lastModified: Date(),
                    userCreated: true
                )
            )
        }
    }
}
