import SwiftUI

/// Row view for a pattern item
/// Displays pattern information with computed properties
/// Follows SOLID principles with single responsibility focus
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
/// Comprehensive form for pattern item configuration
/// Follows SOLID principles with single responsibility focus
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
