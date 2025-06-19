import SwiftUI

/// Quiz view for financial literacy and payslip knowledge testing
struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Financial Quiz")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(FintechColors.primaryBlue)
            }
            .padding()
            
            // Content placeholder
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(FintechColors.primaryBlue)
                
                Text("Quiz Feature Coming Soon")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Test your financial knowledge with interactive quizzes based on your payslip data.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Start Sample Quiz") {
                    // Placeholder action
                    Task {
                        await viewModel.startQuiz(
                            questionCount: 5,
                            difficulty: .easy,
                            focusArea: nil
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(FintechColors.primaryBlue)
            }
            .padding()
            
            Spacer()
        }
        .navigationBarHidden(true)
        .background(FintechColors.appBackground)
    }
}

// MARK: - Preview - Simple placeholder without mock services
#if DEBUG
struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Text("Quiz View Placeholder")
                .font(.title)
                .navigationTitle("Quiz")
        }
    }
}
#endif