import SwiftUI

/// Production monitoring dashboard for LiteRT AI integration
struct LiteRTProductionDashboardView: View {
    @StateObject private var productionManager = LiteRTProductionManager.shared
    @StateObject private var featureFlags = LiteRTFeatureFlags.shared

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedEnvironment = LiteRTFeatureFlags.ProductionEnvironment.production
    @State private var rolloutPercentage = 100

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Health Status
                    healthStatusSection

                    // Metrics Dashboard
                    metricsSection

                    // Feature Flags
                    featureFlagsSection

                    // Production Controls
                    productionControlsSection

                    // Model Updates
                    modelUpdatesSection

                    // Emergency Controls
                    emergencyControlsSection
                }
                .padding()
            }
            .navigationTitle("LiteRT Production")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("LiteRT Production"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // Initialize with current values
                selectedEnvironment = featureFlags.currentEnvironment
                rolloutPercentage = featureFlags.rolloutPercentage
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Production Dashboard")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Text("Environment:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(featureFlags.currentEnvironment.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)

                Spacer()

                Text("Rollout: \(featureFlags.rolloutPercentage)%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Status:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                healthStatusBadge
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var healthStatusBadge: some View {
        let status = productionManager.modelHealthStatus

        return HStack(spacing: 4) {
            Circle()
                .fill(healthStatusColor(status))
                .frame(width: 8, height: 8)

            Text(status.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(healthStatusColor(status))
        }
    }

    private func healthStatusColor(_ status: LiteRTProductionManager.ModelHealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .yellow
        case .critical: return .red
        case .offline: return .gray
        case .unknown: return .orange
        }
    }

    // MARK: - Health Status Section

    private var healthStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Status")
                .font(.headline)

            VStack(spacing: 16) {
                // Health indicators
                HStack(spacing: 20) {
                    healthIndicator(
                        title: "Models",
                        status: productionManager.modelHealthStatus.rawValue,
                        color: healthStatusColor(productionManager.modelHealthStatus)
                    )

                    healthIndicator(
                        title: "Performance",
                        status: productionManager.currentMetrics.cpuUsage < 80 ? "Good" : "High",
                        color: productionManager.currentMetrics.cpuUsage < 80 ? .green : .yellow
                    )

                    healthIndicator(
                        title: "Memory",
                        status: productionManager.currentMetrics.memoryUsage < 200_000_000 ? "Normal" : "High",
                        color: productionManager.currentMetrics.memoryUsage < 200_000_000 ? .green : .yellow
                    )
                }

                // Last health check
                HStack {
                    Text("Last Check:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatDate(productionManager.currentMetrics.timestamp))
                        .font(.subheadline)
                    Spacer()
                    Button("Refresh") {
                        productionManager.forceHealthCheck()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func healthIndicator(title: String, status: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(status)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                metricCard(
                    title: "Memory Usage",
                    value: formatBytes(productionManager.currentMetrics.memoryUsage),
                    icon: "memorychip"
                )

                metricCard(
                    title: "CPU Usage",
                    value: String(format: "%.1f%%", productionManager.currentMetrics.cpuUsage),
                    icon: "cpu"
                )

                metricCard(
                    title: "Total Requests",
                    value: "\(productionManager.currentMetrics.totalRequests)",
                    icon: "arrow.up.arrow.down.circle"
                )

                metricCard(
                    title: "Success Rate",
                    value: productionManager.currentMetrics.totalRequests > 0 ?
                        String(format: "%.1f%%", Double(productionManager.currentMetrics.successCount) / Double(productionManager.currentMetrics.totalRequests) * 100) : "0%",
                    icon: "checkmark.circle"
                )

                metricCard(
                    title: "Avg Inference Time",
                    value: String(format: "%.2fms", productionManager.currentMetrics.inferenceTime),
                    icon: "timer"
                )

                metricCard(
                    title: "Error Count",
                    value: "\(productionManager.currentMetrics.errorCount)",
                    icon: "exclamationmark.triangle"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(height: 24)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Feature Flags Section

    private var featureFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feature Flags")
                .font(.headline)

            let featureStatus = featureFlags.getFeatureStatus()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(featureStatus.sorted(by: { $0.key < $1.key }), id: \.key) { feature, enabled in
                    featureFlagToggle(feature: feature, enabled: enabled)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func featureFlagToggle(feature: String, enabled: Bool) -> some View {
        VStack(spacing: 4) {
            Text(feature.replacingOccurrences(of: "LiteRT_", with: "").replacingOccurrences(of: "Enable", with: ""))
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 30)

            Toggle("", isOn: Binding(
                get: { enabled },
                set: { newValue in
                    featureFlags.setFeatureFlag(LiteRTFeatureFlags.FeatureFlag(rawValue: feature) ?? .liteRTService, enabled: newValue)
                }
            ))
            .labelsHidden()
            .scaleEffect(0.8)
        }
        .frame(height: 60)
        .padding(.vertical, 4)
    }

    // MARK: - Production Controls Section

    private var productionControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Production Controls")
                .font(.headline)

            VStack(spacing: 16) {
                // Environment selector
                HStack {
                    Text("Environment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("", selection: $selectedEnvironment) {
                        ForEach(LiteRTFeatureFlags.ProductionEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Rollout percentage
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rollout Percentage: \(rolloutPercentage)%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Apply") {
                            applyProductionConfig()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    Slider(value: Binding(
                        get: { Double(rolloutPercentage) },
                        set: { rolloutPercentage = Int($0) }
                    ), in: 0...100, step: 10)
                    .accentColor(.blue)
                }

                // Quick rollout buttons
                HStack(spacing: 12) {
                    rolloutButton(title: "10%", percentage: 10)
                    rolloutButton(title: "25%", percentage: 25)
                    rolloutButton(title: "50%", percentage: 50)
                    rolloutButton(title: "100%", percentage: 100)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func rolloutButton(title: String, percentage: Int) -> some View {
        Button(action: {
            rolloutPercentage = percentage
            applyProductionConfig()
        }) {
            Text(title)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
    }

    private func applyProductionConfig() {
        featureFlags.configureForEnvironment(selectedEnvironment, rolloutPercentage: rolloutPercentage)
        alertMessage = "Production configuration updated to \(selectedEnvironment.rawValue) with \(rolloutPercentage)% rollout"
        showingAlert = true
    }

    // MARK: - Model Updates Section

    private var modelUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Updates")
                .font(.headline)

            VStack(spacing: 16) {
                // Update status
                HStack {
                    Text("Last Update:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(productionManager.lastModelUpdate.map { formatDate($0) } ?? "Never")
                        .font(.subheadline)
                    Spacer()
                }

                // Available updates
                if !productionManager.availableModelVersions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Updates:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(productionManager.availableModelVersions.sorted(by: { $0.key < $1.key }), id: \.key) { model, version in
                            HStack {
                                Text(model.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.caption)
                                Spacer()
                                Text(version)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        Button("Apply Updates") {
                            Task {
                                do {
                                    try await productionManager.applyModelUpdates()
                                    alertMessage = "Model updates applied successfully"
                                    showingAlert = true
                                } catch {
                                    alertMessage = "Failed to apply updates: \(error.localizedDescription)"
                                    showingAlert = true
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                } else {
                    Button("Check for Updates") {
                        Task {
                            await productionManager.checkForModelUpdates()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Emergency Controls Section

    private var emergencyControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Controls")
                .font(.headline)
                .foregroundColor(.red)

            VStack(spacing: 12) {
                Button(action: {
                    featureFlags.disableAllFeatures()
                    alertMessage = "All LiteRT features disabled"
                    showingAlert = true
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Emergency Disable All")
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                Button(action: {
                    productionManager.forceHealthCheck()
                    alertMessage = "Health check initiated"
                    showingAlert = true
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.green)
                        Text("Force Health Check")
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                Button(action: {
                    productionManager.resetMetrics()
                    alertMessage = "Metrics reset"
                    showingAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.blue)
                        Text("Reset Metrics")
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Utilities

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Preview

struct LiteRTProductionDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        LiteRTProductionDashboardView()
    }
}
