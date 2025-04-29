import SwiftUI

/// Demonstrates the feature flag system by showing a list of features and allowing them to be toggled.
struct FeatureFlagDemoView: View {
    @State private var features: [Feature] = Feature.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    @State private var refreshingConfiguration = false
    
    var body: some View {
        List {
            Section(header: Text("Core Features")) {
                featureToggles(for: [.optimizedMilitaryParsing, .parallelizedTextExtraction, .enhancedPatternMatching])
            }
            
            Section(header: Text("UI Features")) {
                featureToggles(for: [.enhancedDashboard, .militaryInsights, .pdfAnnotation])
            }
            
            Section(header: Text("Analytics Features")) {
                featureToggles(for: [.enhancedAnalytics, .dataAggregation])
            }
            
            Section(header: Text("Experimental Features")) {
                featureToggles(for: [.aiCategorization, .smartCapture, .cloudBackup])
            }
            
            Section(header: Text("Demo Components")) {
                demoComponents
            }
            
            Section(header: Text("Actions")) {
                Button(action: refreshConfiguration) {
                    HStack {
                        Text("Refresh Configuration")
                        if refreshingConfiguration {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                }
                
                Button(action: resetAll) {
                    Text("Reset All Overrides")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Feature Flags")
    }
    
    /// Creates toggle buttons for the given features.
    /// - Parameter features: The features to create toggles for.
    /// - Returns: A list of toggle views.
    private func featureToggles(for features: [Feature]) -> ForEach<[Feature], Feature, FeatureToggleRow> {
        return ForEach(features, id: \.self) { feature in
            FeatureToggleRow(feature: feature)
        }
    }
    
    /// Shows demo components that use feature flags.
    private var demoComponents: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("These components demonstrate the feature flag system in real use.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Enhanced Dashboard")
                    .font(.headline)
                
                Text("Without feature flag:")
                StandardDashboardView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                Text("With feature flag:")
                DashboardView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("PDF Annotation")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "doc.text")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading) {
                        Text("Sample.pdf")
                        Text("Last modified: Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "pencil")
                    }
                    .featureEnabled(.pdfAnnotation)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Refreshes the feature flag configuration from the remote source.
    private func refreshConfiguration() {
        refreshingConfiguration = true
        
        FeatureFlagManager.shared.refreshConfiguration { success in
            DispatchQueue.main.async {
                refreshingConfiguration = false
                
                if success {
                    // Show success message
                } else {
                    // Show error message
                }
            }
        }
    }
    
    /// Resets all feature flag overrides.
    private func resetAll() {
        for feature in Feature.allCases {
            FeatureFlagManager.shared.resetFeature(feature)
        }
    }
}

/// A row that displays a feature toggle.
struct FeatureToggleRow: View {
    let feature: Feature
    @State private var isEnabled: Bool = false
    
    var body: some View {
        Toggle(isOn: $isEnabled) {
            VStack(alignment: .leading) {
                Text(feature.rawValue.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression, range: nil).capitalized)
                Text(featureDescription(for: feature))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isEnabled = FeatureFlagManager.shared.isEnabled(feature)
        }
        .onChange(of: isEnabled) { oldValue, newValue in
            FeatureFlagManager.shared.toggleFeature(feature, enabled: newValue)
        }
    }
    
    /// Gets a description for the given feature.
    /// - Parameter feature: The feature to get a description for.
    /// - Returns: A description of the feature.
    private func featureDescription(for feature: Feature) -> String {
        switch feature {
        case .optimizedMilitaryParsing:
            return "Reduces memory usage at the cost of speed"
        case .parallelizedTextExtraction:
            return "Uses multiple threads for faster PDF text extraction"
        case .enhancedPatternMatching:
            return "Improved pattern recognition for payslip data"
        case .enhancedDashboard:
            return "New dashboard with graphical summaries"
        case .militaryInsights:
            return "Military-specific insights and analysis"
        case .pdfAnnotation:
            return "Markup and annotation tools for PDF documents"
        case .enhancedAnalytics:
            return "Extended application analytics"
        case .dataAggregation:
            return "Anonymized data aggregation for trends"
        case .aiCategorization:
            return "AI-powered payslip categorization"
        case .smartCapture:
            return "Automatic document capture with quality detection"
        case .cloudBackup:
            return "Secure cloud backup functionality"
        }
    }
}

/// A standard dashboard view that doesn't use feature flags.
struct StandardDashboardView: View {
    var body: some View {
        HStack {
            Image(systemName: "list.bullet")
            Text("Standard Dashboard")
            Spacer()
        }
        .padding(.horizontal)
    }
}

/// A dashboard view that demonstrates feature flags.
struct DashboardView: View {
    var body: some View {
        HStack {
            if FeatureFlagManager.shared.isEnabled(.enhancedDashboard) {
                Image(systemName: "chart.bar.xaxis")
                Text("Enhanced Dashboard")
                Spacer()
                Image(systemName: "chart.pie")
            } else {
                Image(systemName: "list.bullet")
                Text("Standard Dashboard")
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct FeatureFlagDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeatureFlagDemoView()
        }
    }
} 