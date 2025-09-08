import SwiftUI

/// View for creating or editing a pattern
/// Orchestrates pattern editing workflow using extracted components
/// Follows SOLID principles with single responsibility focus
struct PatternEditView: View {

    // MARK: - Properties

    // Environment
    @Environment(\.dismiss) private var dismiss

    // Dependencies
    @StateObject private var viewModel: PatternEditViewModel

    // State
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingError = false
    @State private var isShowingTestPatternView = false
    @State private var isShowingAddPatternItemSheet = false

    let isNewPattern: Bool
    private var currentPattern: PatternDefinition {
        viewModel.patternValidationVM.currentPattern
    }

    // MARK: - Initialization

    init(pattern: PatternDefinition? = nil, isNewPattern: Bool) {
        self.isNewPattern = isNewPattern

        // Initialize ViewModel
        let editVM = PatternEditViewModel()
        editVM.configure(with: pattern)

        self._viewModel = StateObject(wrappedValue: editVM)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Basic info section using existing component
                PatternFormView(pattern: Binding(
                    get: { currentPattern },
                    set: { newValue in
                        viewModel.patternValidationVM.patternName = newValue.name
                        viewModel.patternValidationVM.patternKey = newValue.key
                        viewModel.patternValidationVM.patternCategory = newValue.category
                    }
                ))

                // Pattern items section using existing component
                PatternListView(
                    viewModel: viewModel.patternListVM,
                    isShowingTestPatternView: $isShowingTestPatternView,
                    pattern: currentPattern
                )

                // Save button
                Section {
                    Button {
                        savePattern()
                    } label: {
                        Text("Save Pattern")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(!viewModel.patternValidationVM.isValid)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle(isNewPattern ? "New Pattern" : "Edit Pattern")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if !isNewPattern && !currentPattern.isCore {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Delete Pattern", isPresented: $isShowingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deletePattern(currentPattern)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this pattern? This action cannot be undone.")
            }
            .alert("Error", isPresented: $isShowingError) {
                Button("OK", role: .cancel) {
                    isShowingError = false
                    viewModel.patternManagementVM.showError = false
                }
            } message: {
                Text(viewModel.patternManagementVM.errorMessage)
            }
            .onChange(of: viewModel.patternManagementVM.showError) { oldValue, newValue in
                if newValue {
                    isShowingError = true
                }
            }
            .sheet(isPresented: $isShowingAddPatternItemSheet) {
                PatternItemEditView { newItem in
                    viewModel.patternListVM.addPatternItem(newItem)
                    isShowingAddPatternItemSheet = false
                }
            }
            .onChange(of: viewModel.patternListVM.isShowingAddPatternItemSheet) { oldValue, newValue in
                if newValue {
                    isShowingAddPatternItemSheet = true
                }
            }
            .onChange(of: isShowingAddPatternItemSheet) { oldValue, newValue in
                if !newValue {
                    viewModel.patternListVM.isShowingAddPatternItemSheet = false
                }
            }
            .sheet(isPresented: $isShowingTestPatternView) {
                PatternTestingView(pattern: currentPattern)
            }
        }
    }

    // MARK: - Actions

    private func savePattern() {
        viewModel.savePattern()
        dismiss()
    }
}

// MARK: - Preview

struct PatternEditView_Previews: PreviewProvider {
    static var previews: some View {
        PatternEditView(isNewPattern: true)
    }
}
