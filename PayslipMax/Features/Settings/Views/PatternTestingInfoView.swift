import SwiftUI

/// View component for displaying pattern information in the pattern testing interface
struct PatternTestingInfoView: View {
    // MARK: - Properties

    let pattern: PatternDefinition

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title section with proper spacing
            titleSection

            // Key and Category information with better spacing
            infoGrid

            Divider()
                .padding(.vertical, 4)

            // Pattern items count
            patternCountSection

            // Pattern list with visual improvements
            patternListSection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    // MARK: - Subviews

    private var titleSection: some View {
        Text(pattern.name)
            .font(.title2)
            .fontWeight(.bold)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }

    private var infoGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                Text("Key:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .gridColumnAlignment(.trailing)

                Text(pattern.key)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .gridColumnAlignment(.leading)
            }

            GridRow {
                Text("Category:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .gridColumnAlignment(.trailing)

                Text(pattern.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .gridColumnAlignment(.leading)
            }
        }
    }

    private var patternCountSection: some View {
        HStack {
            Text("Pattern items:")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("\(pattern.patterns.count)")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private var patternListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(pattern.patterns) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: patternTypeIcon(for: item.type))
                        .foregroundColor(.accentColor)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(patternTypeTitle(for: item.type))
                            .font(.caption)
                            .fontWeight(.semibold)

                        Text(item.pattern)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.leading, 4)
    }

    // MARK: - Helpers

    private func patternTypeIcon(for type: ExtractorPatternType) -> String {
        switch type {
        case .regex:
            return "r.square"
        case .keyword:
            return "k.square"
        case .positionBased:
            return "arrow.left.and.right.square"
        }
    }

    private func patternTypeTitle(for type: ExtractorPatternType) -> String {
        switch type {
        case .regex:
            return "Regex Pattern"
        case .keyword:
            return "Keyword Pattern"
        case .positionBased:
            return "Position-Based Pattern"
        }
    }
}

/// Preview provider for PatternTestingInfoView
struct PatternTestingInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let samplePattern = PatternDefinition.createUserPattern(
            name: "Basic Pay",
            key: "basicPay",
            category: .earnings,
            patterns: [
                ExtractorPattern.regex(
                    pattern: "BASIC PAY:\\s*([0-9,.]+)",
                    priority: 10
                ),
                ExtractorPattern.keyword(
                    keyword: "BASIC PAY",
                    contextAfter: "Rs.",
                    priority: 5
                )
            ]
        )

        PatternTestingInfoView(pattern: samplePattern)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
