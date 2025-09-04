import SwiftUI

/// Individual quiz question card component with answer options and explanation
struct QuizQuestionCard: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: String?
    @Binding var isAnswerSubmitted: Bool
    @Binding var showExplanation: Bool
    
    let onSubmitAnswer: (String) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Question card
            VStack(alignment: .leading, spacing: 16) {
                // Difficulty badge
                HStack {
                    Label(question.difficulty.displayName, systemImage: question.difficulty.iconName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(question.difficulty.color.opacity(0.2))
                        .foregroundColor(question.difficulty.color)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text("+\(question.pointsValue) pts")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.premiumGold)
                }
                
                Text(question.questionText)
                    .font(.title3)
                    .fontWeight(.medium)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            
            // Answer options
            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    answerOptionButton(option: option, correctAnswer: question.correctAnswer)
                }
            }
            
            // Show explanation after answer is submitted
            if showExplanation && isAnswerSubmitted {
                explanationView(question.explanation, correct: selectedAnswer == question.correctAnswer)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAnswerSubmitted)
        .animation(.easeInOut(duration: 0.3), value: showExplanation)
    }
    
    // MARK: - Answer Option Button
    
    private func answerOptionButton(option: String, correctAnswer: String) -> some View {
        Button(action: {
            guard !isAnswerSubmitted else { return }
            selectedAnswer = option
            onSubmitAnswer(option)
        }) {
            HStack {
                Text(option)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Show checkmark/X after submission
                if isAnswerSubmitted {
                    if option == correctAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if option == selectedAnswer {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonBackgroundColor(option: option, correctAnswer: correctAnswer))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(buttonBorderColor(option: option, correctAnswer: correctAnswer), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAnswerSubmitted)
    }
    
    private func buttonBackgroundColor(option: String, correctAnswer: String) -> Color {
        if !isAnswerSubmitted {
            return selectedAnswer == option ? FintechColors.primaryBlue.opacity(0.1) : Color(UIColor.secondarySystemBackground)
        }
        
        if option == correctAnswer {
            return Color.green.opacity(0.2)
        } else if option == selectedAnswer {
            return Color.red.opacity(0.2)
        } else {
            return Color(UIColor.secondarySystemBackground)
        }
    }
    
    private func buttonBorderColor(option: String, correctAnswer: String) -> Color {
        if !isAnswerSubmitted {
            return selectedAnswer == option ? FintechColors.primaryBlue : Color.clear
        }
        
        if option == correctAnswer {
            return Color.green
        } else if option == selectedAnswer {
            return Color.red
        } else {
            return Color.clear
        }
    }
    
    // MARK: - Explanation View
    
    private func explanationView(_ explanation: String, correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(correct ? .green : .red)
                
                Text(correct ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(correct ? .green : .red)
                
                Spacer()
                
                // Star feedback
                HStack(spacing: 4) {
                    Image(systemName: correct ? "plus.circle.fill" : "minus.circle.fill")
                        .foregroundColor(correct ? .green : .red)
                        .font(.caption)
                    
                    Text(correct ? "+\(question.pointsValue)" : "-1")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(correct ? .green : .red)
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((correct ? Color.green : Color.red).opacity(0.1))
                )
            }
            
            Text(explanation)
                .font(.body)
                .foregroundColor(.secondary)
                
            if !correct {
                Text("Don't worry! Keep practicing to improve your financial literacy.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((correct ? Color.green : Color.red).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((correct ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Preview
#if DEBUG
struct QuizQuestionCard_Previews: PreviewProvider {
    static var previews: some View {
        QuizQuestionCard(
            question: QuizQuestion(
                questionText: "What is the primary deduction in your payslip?",
                questionType: .multipleChoice,
                options: ["Tax", "Insurance", "Provident Fund", "Professional Tax"],
                correctAnswer: "Tax",
                explanation: "Tax is typically the largest deduction from your gross salary.",
                difficulty: .medium,
                relatedInsightType: .deductions,
                contextData: QuizContextData(
                    userIncome: nil,
                    userTaxRate: nil,
                    userDSOPContribution: nil,
                    averageIncome: nil,
                    comparisonPeriod: nil,
                    specificMonth: nil,
                    calculationDetails: nil
                )
            ),
            selectedAnswer: .constant(nil),
            isAnswerSubmitted: .constant(false),
            showExplanation: .constant(false),
            onSubmitAnswer: { _ in }
        )
        .padding()
    }
}
#endif
