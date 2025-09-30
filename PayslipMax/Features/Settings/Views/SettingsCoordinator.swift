import SwiftUI
import SwiftData

struct SettingsCoordinator: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var coordinator: AppCoordinator

    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - 1. Pro Features
                    ProFeaturesSettingsSection(viewModel: viewModel)

                    // MARK: - 2. Preferences
                    PreferencesSettingsView(viewModel: viewModel)

                    // MARK: - 3. Data Management
                    DataManagementSettingsView(viewModel: viewModel)

                    // MARK: - 4. Support
                    SupportSettingsView(viewModel: viewModel)

                    // MARK: - 5. About
                    AboutSettingsView()
                        .environmentObject(coordinator)

                    // MARK: - 6. Developer Tools
                    DeveloperSettingsSection()

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(FintechColors.appBackground)
            .navigationTitle("Settings")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(FintechColors.textSecondary.opacity(0.1))
                }
            }
        }
        .onAppear {
            // Only load payslips if we need to - this avoids unnecessary data fetching
            if viewModel.payslips.isEmpty && !viewModel.isLoading {
                viewModel.loadPayslips(context: modelContext)
            }
        }
    }
}

// MARK: - Pro Features Section
struct ProFeaturesSettingsSection: View {
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var subscriptionManager: SubscriptionManager
    @State private var showingSubscriptionSheet = false
    @State private var showingBackupSheet = false

    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        // Get subscription manager from DI container
        let featureContainer = DIContainer.shared.featureContainerPublic
        self._subscriptionManager = StateObject(wrappedValue: featureContainer.makeSubscriptionManager())
    }

    var body: some View {
        SettingsSection(title: "PRO FEATURES") {
            VStack(spacing: 0) {
                // PayslipMax Pro
                SettingsRow(
                    icon: subscriptionManager.isPremiumUser ? "crown.fill" : "crown",
                    iconColor: subscriptionManager.isPremiumUser ? FintechColors.warningAmber : FintechColors.textSecondary,
                    title: subscriptionManager.isPremiumUser ? "PayslipMax Pro" : "Go Pro - ₹99/Year",
                    subtitle: subscriptionManager.isPremiumUser ? "Active subscription" : "Cloud backup & cross-device sync",
                    action: {
                        showingSubscriptionSheet = true
                    }
                )

                FintechDivider()

                // Backup & Restore
                SettingsRow(
                    icon: "icloud.and.arrow.up",
                    iconColor: subscriptionManager.isPremiumUser ? FintechColors.primaryBlue : FintechColors.textSecondary,
                    title: "Backup & Restore",
                    subtitle: subscriptionManager.isPremiumUser ? "Export to any cloud service or import from backup" : "Pro feature - Secure cloud backup",
                    action: {
                        showingBackupSheet = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingSubscriptionSheet) {
            PremiumPaywallView()
        }
        .sheet(isPresented: $showingBackupSheet) {
            BackupViewWrapper()
        }
    }
}

// MARK: - Developer Section
struct DeveloperSettingsSection: View {
    @State private var showingFeatureFlags = false

    var body: some View {
        SettingsSection(title: "DEVELOPER TOOLS") {
            VStack(spacing: 0) {
                // Feature Flags
                SettingsRow(
                    icon: "flag.fill",
                    iconColor: FintechColors.primaryBlue,
                    title: "Feature Flags",
                    subtitle: "Toggle experimental features and test new functionality",
                    action: {
                        showingFeatureFlags = true
                    }
                )

                FintechDivider()

                // Performance Debug
                SettingsRow(
                    icon: "hammer.fill",
                    iconColor: FintechColors.warningAmber,
                    title: "Performance Debug",
                    subtitle: "Toggle performance warning logs",
                    action: {
                        let settings = PerformanceDebugSettings.shared
                        settings.isPerformanceWarningLogsEnabled.toggle()
                    }
                )
            }
        }
        .sheet(isPresented: $showingFeatureFlags) {
            NavigationView {
                FeatureFlagDemoView()
                    .navigationTitle("Feature Flags")
                    .navigationBarItems(trailing: Button("Done") {
                        showingFeatureFlags = false
                    })
            }
        }
    }
}

#Preview {
    SettingsCoordinator(viewModel: DIContainer.shared.makeSettingsViewModel())
}
