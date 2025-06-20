import SwiftUI

/// Quiz section component for the Home screen
/// Displays personalized payslip knowledge quiz
@MainActor
struct HomeQuizSection: View {
    let payslips: [AnyPayslip]
    @State private var showQuizSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payslip Quiz")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)
                        .font(.caption)
                    Text("0")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
            
            Text("Test your knowledge of your payslip data")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
            
            Button(action: {
                showQuizSheet = true
            }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                    Text("Start Quiz")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [FintechColors.primaryBlue, FintechColors.secondaryBlue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(FintechColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showQuizSheet) {
            // Placeholder for quiz - will use proper initialization later
            NavigationView {
                Text("Quiz Coming Soon")
                    .navigationTitle("Payslip Quiz")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showQuizSheet = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    HomeQuizSection(payslips: [])
        .padding()
} 