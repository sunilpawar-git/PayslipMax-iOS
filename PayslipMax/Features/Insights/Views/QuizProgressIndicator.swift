import SwiftUI

/// Quiz progress indicator component with header, progress bar, and star count
struct QuizProgressIndicator: View {
    let currentQuestionNumber: Int
    let totalQuestions: Int
    let quizProgress: Double
    let totalPoints: Int
    let starAnimation: Bool
    let hasActiveSession: Bool
    let showResults: Bool
    
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Financial Quiz")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                Button("Close") {
                    onClose()
                }
                .foregroundColor(FintechColors.primaryBlue)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Progress indicator
            if hasActiveSession || showResults {
                VStack(spacing: 8) {
                    HStack {
                        Text("Question \(currentQuestionNumber) of \(totalQuestions)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(FintechColors.premiumGold)
                                .font(.caption)
                                .scaleEffect(starAnimation ? 1.3 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: starAnimation)
                            
                            Text("\(totalPoints)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(starAnimation ? FintechColors.premiumGold : FintechColors.textPrimary)
                                .scaleEffect(starAnimation ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: starAnimation)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(FintechColors.premiumGold.opacity(starAnimation ? 0.2 : 0.0))
                                .animation(.easeInOut(duration: 0.3), value: starAnimation)
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    
                    ProgressView(value: quizProgress)
                        .tint(FintechColors.primaryBlue)
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
        .background(.regularMaterial)
    }
}

// MARK: - Preview
#if DEBUG
struct QuizProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            QuizProgressIndicator(
                currentQuestionNumber: 3,
                totalQuestions: 5,
                quizProgress: 0.6,
                totalPoints: 45,
                starAnimation: false,
                hasActiveSession: true,
                showResults: false,
                onClose: {}
            )
            
            Spacer()
        }
    }
}
#endif
