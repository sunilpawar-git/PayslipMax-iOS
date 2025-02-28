import SwiftUI

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PremiumUpgradeViewModel
    
    init(viewModel: PremiumUpgradeViewModel? = nil) {
        let vm = viewModel ?? DIContainer.shared.makePremiumUpgradeViewModel()
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    featuresView
                    upgradeButton
                }
                .padding()
            }
            .navigationTitle("Premium Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .task {
            await viewModel.checkPremiumStatus()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.yellow)
            
            Text("Upgrade to Premium")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Unlock powerful features to get the most out of your payslips")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private var featuresView: some View {
        VStack(spacing: 16) {
            Text("Premium Features")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(viewModel.features, id: \.self) { feature in
                HStack(spacing: 16) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                    
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
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var upgradeButton: some View {
        Button {
            Task {
                await viewModel.upgradeAction()
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("Upgrade Now")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(viewModel.isLoading)
    }
}

#Preview {
    PremiumUpgradeView()
}