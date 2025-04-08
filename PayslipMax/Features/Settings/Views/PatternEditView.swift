import SwiftUI

/// View for creating or editing a pattern
struct PatternEditView: View {
    
    // MARK: - Properties
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    
    // State
    @StateObject private var viewModel = PatternManagementViewModel()
    @State private var pattern: PatternDefinition
    @State private var patternItems: [ExtractorPattern]
    @State private var showingAddPatternItemSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingTestPatternView = false
    
    let isNewPattern: Bool
    
    // MARK: - Initialization
    
    init(pattern: PatternDefinition? = nil, isNewPattern: Bool) {
        self.isNewPattern = isNewPattern
        
        if let pattern = pattern {
            _pattern = State(initialValue: pattern)
            _patternItems = State(initialValue: pattern.patterns)
        } else {
            // Create a new empty pattern
            _pattern = State(initialValue: PatternDefinition(
                id: UUID(),
                name: "",
                key: "",
                category: .personal,
                patterns: [],
                isCore: false,
                dateCreated: Date(),
                lastModified: Date(),
                userCreated: true
            ))
            _patternItems = State(initialValue: [])
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic info section
                Section("Basic Information") {
                    TextField("Pattern Name", text: $pattern.name)
                    
                    TextField("Pattern Key", text: $pattern.key)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Picker("Category", selection: $pattern.category) {
                        ForEach(PatternCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                // Pattern items section
                Section {
                    ForEach(patternItems.indices, id: \.self) { index in
                        PatternItemRow(pattern: $patternItems[index])
                    }
                    .onDelete { indices in
                        patternItems.remove(atOffsets: indices)
                    }
                    
                    Button {
                        showingAddPatternItemSheet = true
                    } label: {
                        Label("Add Pattern Item", systemImage: "plus")
                    }
                } header: {
                    Text("Pattern Items")
                } footer: {
                    Text("Pattern items define how to extract values from PDF text. Multiple items provide fallbacks if the primary patterns don't match.")
                }
                
                // Test pattern section
                if !patternItems.isEmpty {
                    Section {
                        Button {
                            // Create a temporary pattern with the current items for testing
                            pattern.patterns = patternItems
                            isShowingTestPatternView = true
                        } label: {
                            Label("Test Pattern", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(patternItems.isEmpty)
                    } footer: {
                        Text("Test how this pattern extracts data from a real PDF document.")
                    }
                }
                
                // Save button
                Section {
                    Button {
                        savePattern()
                    } label: {
                        Text("Save Pattern")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(!isValid)
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
                
                if !isNewPattern && !pattern.isCore {
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
                    viewModel.deletePattern(pattern)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this pattern? This action cannot be undone.")
            }
            .sheet(isPresented: $showingAddPatternItemSheet) {
                PatternItemEditView { newItem in
                    patternItems.append(newItem)
                }
            }
            .sheet(isPresented: $isShowingTestPatternView) {
                // Create a temporary pattern with the current items for testing
                let testPattern = PatternDefinition(
                    id: pattern.id,
                    name: pattern.name,
                    key: pattern.key,
                    category: pattern.category,
                    patterns: patternItems,
                    isCore: pattern.isCore,
                    dateCreated: pattern.dateCreated,
                    lastModified: Date(),
                    userCreated: pattern.userCreated
                )
                PatternTestingView(pattern: testPattern)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func savePattern() {
        // Update the pattern with the latest items
        pattern.patterns = patternItems
        
        // Save the pattern
        viewModel.savePattern(pattern)
        
        // Dismiss the view
        dismiss()
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !pattern.name.isEmpty && 
        !pattern.key.isEmpty && 
        !patternItems.isEmpty
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
    
    // State
    @State private var patternType: PatternType = .regex
    @State private var regexPattern = ""
    @State private var keyword = ""
    @State private var contextBefore = ""
    @State private var contextAfter = ""
    @State private var lineOffset = 0
    @State private var startPosition: Int? = nil
    @State private var endPosition: Int? = nil
    @State private var priority = 10
    @State private var selectedPreprocessing: Set<ExtractorPattern.PreprocessingStep> = []
    @State private var selectedPostprocessing: Set<ExtractorPattern.PostprocessingStep> = []
    
    // Callback
    var onSave: (ExtractorPattern) -> Void
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Pattern type section
                Section {
                    Picker("Pattern Type", selection: $patternType) {
                        Text("Regular Expression").tag(PatternType.regex)
                        Text("Keyword").tag(PatternType.keyword)
                        Text("Position-Based").tag(PatternType.position)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Pattern Type")
                }
                
                // Pattern details section
                Section {
                    switch patternType {
                    case .regex:
                        TextField("Regular Expression", text: $regexPattern)
                    case .keyword:
                        TextField("Keyword", text: $keyword)
                        TextField("Context Before (Optional)", text: $contextBefore)
                        TextField("Context After (Optional)", text: $contextAfter)
                    case .position:
                        Stepper("Line Offset: \(lineOffset)", value: $lineOffset, in: -10...10)
                        
                        HStack {
                            Text("Start Position:")
                            TextField("Optional", value: $startPosition, format: .number)
                                .keyboardType(.numberPad)
                        }
                        
                        HStack {
                            Text("End Position:")
                            TextField("Optional", value: $endPosition, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                } header: {
                    Text("Pattern Details")
                }
                
                // Priority section
                Section {
                    Stepper("Priority: \(priority)", value: $priority, in: 1...100)
                } header: {
                    Text("Priority")
                } footer: {
                    Text("Higher priority patterns are tried first when extracting data.")
                }
                
                // Preprocessing section
                Section {
                    ForEach(ExtractorPattern.PreprocessingStep.allCases, id: \.self) { step in
                        Toggle(step.description, isOn: Binding(
                            get: { selectedPreprocessing.contains(step) },
                            set: { isOn in
                                if isOn {
                                    selectedPreprocessing.insert(step)
                                } else {
                                    selectedPreprocessing.remove(step)
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
                            get: { selectedPostprocessing.contains(step) },
                            set: { isOn in
                                if isOn {
                                    selectedPostprocessing.insert(step)
                                } else {
                                    selectedPostprocessing.remove(step)
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
                    .disabled(!isValid)
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
        // Create the extraction pattern
        let extractionPattern: ExtractorPattern
        
        switch patternType {
        case .regex:
            extractionPattern = .regex(
                pattern: regexPattern,
                preprocessing: Array(selectedPreprocessing),
                postprocessing: Array(selectedPostprocessing),
                priority: priority
            )
        case .keyword:
            extractionPattern = .keyword(
                keyword: keyword,
                contextBefore: contextBefore.isEmpty ? nil : contextBefore,
                contextAfter: contextAfter.isEmpty ? nil : contextAfter,
                preprocessing: Array(selectedPreprocessing),
                postprocessing: Array(selectedPostprocessing),
                priority: priority
            )
        case .position:
            extractionPattern = .positionBased(
                lineOffset: lineOffset,
                startPosition: startPosition,
                endPosition: endPosition,
                preprocessing: Array(selectedPreprocessing),
                postprocessing: Array(selectedPostprocessing),
                priority: priority
            )
        }
        
        // Call the callback
        onSave(extractionPattern)
        
        // Dismiss the view
        dismiss()
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        switch patternType {
        case .regex:
            return !regexPattern.isEmpty
        case .keyword:
            return !keyword.isEmpty
        case .position:
            return true
        }
    }
    
    // MARK: - Pattern Type Enum
    
    enum PatternType {
        case regex
        case keyword
        case position
    }
}

// MARK: - Extensions

extension ExtractorPattern.PreprocessingStep {
    var description: String {
        switch self {
        case .normalizeNewlines:
            return "Normalize Newlines"
        case .normalizeCase:
            return "Convert to Lowercase"
        case .removeWhitespace:
            return "Remove Whitespace"
        case .normalizeSpaces:
            return "Normalize Spaces"
        case .trimLines:
            return "Trim Lines"
        }
    }
}

extension ExtractorPattern.PostprocessingStep {
    var description: String {
        switch self {
        case .trim:
            return "Trim Whitespace"
        case .formatAsCurrency:
            return "Format as Currency"
        case .removeNonNumeric:
            return "Remove Non-Numeric"
        case .uppercase:
            return "Convert to Uppercase"
        case .lowercase:
            return "Convert to Lowercase"
        }
    }
}

// MARK: - Preview

struct PatternEditView_Previews: PreviewProvider {
    static var previews: some View {
        PatternEditView(isNewPattern: true)
    }
} 