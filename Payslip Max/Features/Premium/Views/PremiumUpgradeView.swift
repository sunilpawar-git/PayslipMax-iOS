import SwiftUI

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
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    PremiumUpgradeView()
} 