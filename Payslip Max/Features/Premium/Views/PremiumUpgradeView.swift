import SwiftUI

// Import DIContainer
class DIContainer {
    static let shared = DIContainer()
    
    func makePremiumUpgradeViewModel() -> PremiumUpgradeViewModel {
        return PremiumUpgradeViewModel(
            premiumFeatureManager: PremiumFeatureManager.shared,
            cloudRepository: PlaceholderCloudRepository(
                premiumFeatureManager: PremiumFeatureManager.shared
            )
        )
    }
}

// Placeholder implementation
class PlaceholderCloudRepository: CloudRepositoryProtocol {
    private let premiumFeatureManager: PremiumFeatureManager
    
    init(premiumFeatureManager: PremiumFeatureManager) {
        self.premiumFeatureManager = premiumFeatureManager
    }
    
    func syncPayslips() async throws {
        throw NSError(domain: "Not implemented", code: -1)
    }
    
    func backupPayslips() async throws {
        throw NSError(domain: "Not implemented", code: -1)
    }
    
    func fetchBackups() async throws -> [PayslipBackup] {
        throw NSError(domain: "Not implemented", code: -1)
    }
    
    func restorePayslips() async throws {
        throw NSError(domain: "Not implemented", code: -1)
    }
}

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PremiumUpgradeViewModel
    
    init() {
        let container = DIContainer.shared
        _viewModel = StateObject(
            wrappedValue: container.makePremiumUpgradeViewModel()
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("Upgrade to Premium")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Unlock all features and get the most out of Payslip Max")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Features list
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.availableFeatures) { feature in
                            FeatureRow(feature: feature)
                        }
                    }
                    .padding()
                }
                
                // Pricing
                VStack(spacing: 8) {
                    Text("$4.99 / month")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("or $49.99 / year (save 17%)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.upgradeToPremium()
                        }
                    } label: {
                        Text("Upgrade Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 100, height: 100)
                        )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: .constant(viewModel.error != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct FeatureRow: View {
    let feature: PremiumUpgradeViewModel.PremiumFeature
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.rawValue)
                    .font(.headline)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    PremiumUpgradeView()
} 