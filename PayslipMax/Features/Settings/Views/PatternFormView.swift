import SwiftUI

/// View component for editing pattern basic information
struct PatternFormView: View {
    // MARK: - Properties

    @Binding var pattern: PatternDefinition

    // MARK: - Body

    var body: some View {
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
    }
}

// MARK: - Preview

struct PatternFormView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            PatternFormView(pattern: .constant(PatternDefinition(
                id: UUID(),
                name: "Sample Pattern",
                key: "sample",
                category: .personal,
                patterns: [],
                isCore: false,
                dateCreated: Date(),
                lastModified: Date(),
                userCreated: true
            )))
        }
    }
}
