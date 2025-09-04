import SwiftUI

/// Starting view for quiz with instructions and scoring rules
struct QuizStartView: View {
    let onStartQuiz: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(FintechColors.primaryBlue)
            
            VStack(spacing: 12) {
                Text("Ready to Test Your Knowledge?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Answer questions about your payslip data and earn points!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Scoring Rules Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)
                    Text("How Scoring Works")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Easy questions: +1 star")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Medium questions: +2 stars")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Hard questions: +3 stars")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Wrong answers: -1 star")
                            .font(.subheadline)
                    }
                }
                
                Text("Higher star count indicates better financial literacy about your payslips. Challenge yourself!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FintechColors.premiumGold.opacity(0.3), lineWidth: 1)
                    )
            )
            
            VStack(spacing: 12) {
                Button("Start Quiz") {
                    onStartQuiz(5)
                }
                .buttonStyle(.borderedProminent)
                .tint(FintechColors.primaryBlue)
                .controlSize(.large)
                
                Button("Quick Quiz (3 Questions)") {
                    onStartQuiz(3)
                }
                .buttonStyle(.bordered)
                .tint(FintechColors.primaryBlue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
}

// MARK: - Preview
#if DEBUG
struct QuizStartView_Previews: PreviewProvider {
    static var previews: some View {
        QuizStartView { count in
            print("Starting quiz with \(count) questions")
        }
    }
}
#endif
