import SwiftUI

/// View for creating or editing a pattern
struct PatternEditView: View {

    // MARK: - Properties

    // Environment
    @Environment(\.dismiss) private var dismiss

    // Dependencies
    @StateObject private var patternManagementViewModel: PatternManagementViewModel
    @StateObject private var validationViewModel: PatternValidationViewModel
    @StateObject private var listViewModel: PatternListViewModel

    // State
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingTestPatternView = false

    let isNewPattern: Bool

    // MARK: - Initialization

    init(pattern: PatternDefinition? = nil, isNewPattern: Bool) {
        self.isNewPattern = isNewPattern

        // Initialize StateObjects
        let container = DIContainer.shared
        let patternVM = container.makePatternManagementViewModel()
        let validationVM = container.makePatternValidationViewModel()
        let listVM = container.makePatternListViewModel()

        // Configure view models
        if let pattern = pattern {
            validationVM.updateFromPattern(pattern)
            listVM.updatePatternItems(pattern.patterns)
        } else {
            validationVM.createNewPattern()
        }

        self._patternManagementViewModel = StateObject(wrappedValue: patternVM)
        self._validationViewModel = StateObject(wrappedValue: validationVM)
        self._listViewModel = StateObject(wrappedValue: listVM)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Basic info section using extracted component
                PatternFormView(pattern: Binding(
                    get: { validationViewModel.currentPattern },
                    set: { newValue in
                        validationViewModel.patternName = newValue.name
                        validationViewModel.patternKey = newValue.key
                        validationViewModel.patternCategory = newValue.category
                    }
                ))

                // Pattern items section using extracted component
                PatternListView(
                    viewModel: listViewModel,
                    isShowingTestPatternView: $isShowingTestPatternView,
                    pattern: validationViewModel.currentPattern
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
                    .disabled(!validationViewModel.isValid)
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

                if !isNewPattern && !validationViewModel.currentPattern.isCore {
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
                    patternManagementViewModel.deletePattern(validationViewModel.currentPattern)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this pattern? This action cannot be undone.")
            }
            .sheet(isPresented: $listViewModel.isShowingAddPatternItemSheet) {
                PatternItemEditView { newItem in
                    listViewModel.addPatternItem(newItem)
                }
            }
            .sheet(isPresented: $isShowingTestPatternView) {
                PatternTestingView(pattern: validationViewModel.currentPattern)
            }
            .alert("Error", isPresented: $patternManagementViewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(patternManagementViewModel.errorMessage)
            }
        }
    }

    // MARK: - Actions

    private func savePattern() {
        // Create the final pattern with current data
        var finalPattern = validationViewModel.currentPattern
        finalPattern.patterns = listViewModel.patternItems
        finalPattern.lastModified = Date()

        // Save the pattern
        patternManagementViewModel.savePattern(finalPattern)

        // Dismiss the view
        dismiss()
    }
}

/// Row view for a pattern item
struct PatternItemRow: View {
    @Binding var pattern: ExtractorPattern

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Pattern type
            HStack {
                Text(patternTypeTitle)
                    .font(.headline)

                Spacer()

                Text("Priority: \(pattern.priority)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Pattern details
            Text(patternDetails)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Processing steps
            if !pattern.preprocessing.isEmpty {
                Text("Preprocessing: \(preprocessingText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !pattern.postprocessing.isEmpty {
                Text("Postprocessing: \(postprocessingText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Computed Properties

    private var patternTypeTitle: String {
        switch pattern.type {
        case .regex:
            return "Regex Pattern"
        case .keyword:
            return "Keyword Pattern"
        case .positionBased:
            return "Position-Based Pattern"
        }
    }

    private var patternDetails: String {
        switch pattern.type {
        case .regex:
            return "Pattern: \(pattern.pattern)"
        case .keyword:
            let parts = pattern.pattern.split(separator: "|")
            let keyword = parts.count == 1 ? String(parts[0]) : String(parts[1])
            return "Keyword: \(keyword)"
        case .positionBased:
            return "Position: \(pattern.pattern)"
        }
    }

    private var preprocessingText: String {
        pattern.preprocessing.map { "\($0)" }.joined(separator: ", ")
    }

    private var postprocessingText: String {
        pattern.postprocessing.map { "\($0)" }.joined(separator: ", ")
    }
}

/// View for creating or editing a pattern item
struct PatternItemEditView: View {

    // MARK: - Properties

    // Environment
    @Environment(\.dismiss) private var dismiss

    // Dependencies
    @ObservedObject private var viewModel: PatternItemEditViewModel

    // Callback
    var onSave: (ExtractorPattern) -> Void

    // MARK: - Initialization

    init(onSave: @escaping (ExtractorPattern) -> Void) {
        let container = DIContainer.shared
        self.viewModel = container.makePatternItemEditViewModel()
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Pattern type section
                Section {
                    Picker("Pattern Type", selection: $viewModel.patternType) {
                        Text("Regular Expression").tag(ExtractorPatternType.regex)
                        Text("Keyword").tag(ExtractorPatternType.keyword)
                        Text("Position-Based").tag(ExtractorPatternType.positionBased)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Pattern Type")
                }

                // Pattern details section
                Section {
                    switch viewModel.patternType {
                    case .regex:
                        TextField("Regular Expression", text: $viewModel.regexPattern)
                    case .keyword:
                        TextField("Keyword", text: $viewModel.keyword)
                        TextField("Context Before (Optional)", text: $viewModel.contextBefore)
                        TextField("Context After (Optional)", text: $viewModel.contextAfter)
                    case .positionBased:
                        Stepper("Line Offset: \(viewModel.lineOffset)", value: $viewModel.lineOffset, in: -10...10)

                        HStack {
                            Text("Start Position:")
                            TextField("Optional", value: $viewModel.startPosition, format: .number)
                                .keyboardType(.numberPad)
                        }

                        HStack {
                            Text("End Position:")
                            TextField("Optional", value: $viewModel.endPosition, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                } header: {
                    Text("Pattern Details")
                }

                // Priority section
                Section {
                    Stepper("Priority: \(viewModel.priority)", value: $viewModel.priority, in: 1...100)
                } header: {
                    Text("Priority")
                } footer: {
                    Text("Higher priority patterns are tried first when extracting data.")
                }

                // Preprocessing section
                Section {
                    ForEach(ExtractorPattern.PreprocessingStep.allCases, id: \.self) { step in
                        Toggle(step.description, isOn: Binding(
                            get: { viewModel.selectedPreprocessing.contains(step) },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectedPreprocessing.insert(step)
                                } else {
                                    viewModel.selectedPreprocessing.remove(step)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Preprocessing Steps")
                } footer: {
                    Text("Preprocessing is applied to the text before extraction.")
                }

                // Postprocessing section
                Section {
                    ForEach(ExtractorPattern.PostprocessingStep.allCases, id: \.self) { step in
                        Toggle(step.description, isOn: Binding(
                            get: { viewModel.selectedPostprocessing.contains(step) },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectedPostprocessing.insert(step)
                                } else {
                                    viewModel.selectedPostprocessing.remove(step)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Postprocessing Steps")
                } footer: {
                    Text("Postprocessing is applied to the extracted value.")
                }

                // Save button
                Section {
                    Button {
                        savePatternItem()
                    } label: {
                        Text("Add Pattern Item")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(!viewModel.isValid)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("New Pattern Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func savePatternItem() {
        // Call the callback with the extractor pattern from view model
        onSave(viewModel.extractorPattern)

        // Dismiss the view
        dismiss()
    }
}

// MARK: - Preview

struct PatternEditView_Previews: PreviewProvider {
    static var previews: some View {
        PatternEditView(isNewPattern: true)
    }
}
