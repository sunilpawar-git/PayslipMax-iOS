import SwiftUI

// Forward declarations
class PremiumUpgradeViewModel: ObservableObject {
    var isLoading = false
    var errorMessage = ""
    var showSuccessAlert = false
    var showErrorAlert = false
    var availableFeatures: [PremiumFeatureManager.PremiumFeature] = []
}

class DIContainer {
    static let shared = DIContainer()
    func makePremiumUpgradeViewModel() -> PremiumUpgradeViewModel {
        return PremiumUpgradeViewModel()
    }
}

class PremiumFeatureManager {
    enum PremiumFeature: String, CaseIterable, Identifiable {
        case cloudBackup = "Cloud Backup"
        case dataSync = "Data Sync"
        case advancedInsights = "Advanced Insights"
        case exportFeatures = "Export Features"
        case prioritySupport = "Priority Support"
        
        var id: String { rawValue }
        
        var title: String {
            return rawValue
        }
        
        var description: String {
            switch self {
            case .cloudBackup: return "Securely store your payslips in the cloud"
            case .dataSync: return "Access your payslips on all your devices"
            case .advancedInsights: return "Get deeper insights into your finances"
            case .exportFeatures: return "Export detailed reports in multiple formats"
            case .prioritySupport: return "Get priority support from our team"
            }
        }
        
        var icon: String {
            switch self {
            case .cloudBackup: return "icloud"
            case .dataSync: return "arrow.triangle.2.circlepath"
            case .advancedInsights: return "chart.bar"
            case .exportFeatures: return "square.and.arrow.up"
            case .prioritySupport: return "person.fill.questionmark"
            }
        }
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
                    Button(action: {
                        Task {
                            await viewModel.upgradeToPremium()
                        }
                    }) {
                        Text("Upgrade Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("Upgrade Successful", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You now have access to all premium features!")
            }
            .alert("Upgrade Failed", isPresented: $viewModel.showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

struct FeatureRow: View {
    let feature: PremiumFeatureManager.PremiumFeature
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    PremiumUpgradeView()
} 