import SwiftUI

/// Integration view that adds gamification elements to the Insights screen
struct GamificationIntegrationView: View {
    
    @StateObject private var quizViewModel: QuizViewModel
    @State private var showQuizSheet = false
    @State private var showAchievementsSheet = false
    
    // MARK: - Initialization
    
    init(quizViewModel: QuizViewModel) {
        self._quizViewModel = StateObject(wrappedValue: quizViewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Gamification Header
            gamificationHeader
            
            // Quick Quiz Card
            quickQuizCard
            
            // Achievement Showcase
            achievementShowcase
        }
        .padding(.horizontal)
        .sheet(isPresented: $showQuizSheet) {
            NavigationView {
                QuizView(viewModel: quizViewModel)
                    .navigationTitle("Quiz")
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
        .sheet(isPresented: $showAchievementsSheet) {
            achievementsDetailSheet
        }
    }
    
    // MARK: - Gamification Header
    
    private var gamificationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Level \(quizViewModel.userProgress.level) • \(quizViewModel.userProgress.totalPoints) pts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Achievement stars button
            Button(action: {
                showAchievementsSheet = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)
                    
                    Text("\(quizViewModel.getUnlockedAchievements().count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.premiumGold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(FintechColors.premiumGold.opacity(0.15))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Quick Quiz Card
    
    private var quickQuizCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(FintechColors.primaryBlue)
                        
                        Text("Test Your Knowledge")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Answer questions about your payslip data and earn stars!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    if quizViewModel.userProgress.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(quizViewModel.userProgress.currentStreak)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Text("\(Int(quizViewModel.userProgress.accuracyPercentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quiz action buttons
            HStack(spacing: 12) {
                Button("Quick Quiz") {
                    showQuizSheet = true
                }
                .buttonStyle(CompactPrimaryButtonStyle())
                
                Button("Challenge") {
                    // Start a challenging quiz
                    Task {
                        await quizViewModel.startQuiz(
                            questionCount: 10,
                            difficulty: .hard,
                            focusArea: nil
                        )
                        showQuizSheet = true
                    }
                }
                .buttonStyle(CompactSecondaryButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Achievement Showcase
    
    private var achievementShowcase: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showAchievementsSheet = true
                }
                .font(.subheadline)
                .foregroundColor(FintechColors.primaryBlue)
            }
            
            let unlockedAchievements = quizViewModel.getUnlockedAchievements()
            let lockedAchievements = quizViewModel.getLockedAchievements()
            
            if unlockedAchievements.isEmpty && lockedAchievements.isEmpty {
                emptyAchievementsView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Show recent unlocked achievements
                        ForEach(unlockedAchievements.prefix(3)) { achievement in
                            achievementBadgeView(achievement, isUnlocked: true)
                        }
                        
                        // Show progress on next achievements
                        ForEach(lockedAchievements.prefix(2)) { achievement in
                            achievementBadgeView(achievement, isUnlocked: false)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Achievement Badge View
    
    private func achievementBadgeView(_ achievement: Achievement, isUnlocked: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.badgeColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? achievement.badgeColor : .gray)
                
                if !isUnlocked {
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: quizViewModel.getAchievementProgress(achievement) / 100)
                        .stroke(achievement.badgeColor, lineWidth: 2)
                        .frame(width: 54, height: 54)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                    .lineLimit(1)
                
                if !isUnlocked {
                    Text("\(Int(quizViewModel.getAchievementProgress(achievement)))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 70)
    }
    
    // MARK: - Empty Achievements View
    
    private var emptyAchievementsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle")
                .font(.title)
                .foregroundColor(.gray)
            
            Text("No achievements yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Take a quiz to start earning badges!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
    
    // MARK: - Achievements Detail Sheet
    
    private var achievementsDetailSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress summary
                progressSummaryCard
                
                // Achievements list
                List {
                    Section("Unlocked") {
                        let unlockedAchievements = quizViewModel.getUnlockedAchievements()
                        if unlockedAchievements.isEmpty {
                            Text("No achievements unlocked yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(unlockedAchievements) { achievement in
                                achievementRowView(achievement, isUnlocked: true)
                            }
                        }
                    }
                    
                    Section("In Progress") {
                        let lockedAchievements = quizViewModel.getLockedAchievements()
                        if lockedAchievements.isEmpty {
                            Text("All achievements unlocked!")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(lockedAchievements) { achievement in
                                achievementRowView(achievement, isUnlocked: false)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAchievementsSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Summary Card
    
    private var progressSummaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                progressStatItem("Level", "\(quizViewModel.userProgress.level)")
                progressStatItem("Points", "\(quizViewModel.userProgress.totalPoints)")
                progressStatItem("Streak", "\(quizViewModel.userProgress.currentStreak)")
                progressStatItem("Accuracy", "\(Int(quizViewModel.userProgress.accuracyPercentage))%")
            }
            
            // Level progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Level \(quizViewModel.userProgress.level)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Next: \((quizViewModel.userProgress.level + 1) * 100) pts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(
                    value: Double(quizViewModel.userProgress.totalPoints % 100),
                    total: 100
                )
                .progressViewStyle(LinearProgressViewStyle(tint: FintechColors.premiumGold))
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private func progressStatItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Achievement Row View
    
    private func achievementRowView(_ achievement: Achievement, isUnlocked: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.badgeColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: achievement.iconName)
                    .foregroundColor(isUnlocked ? achievement.badgeColor : .gray)
                
                if !isUnlocked {
                    Circle()
                        .trim(from: 0, to: quizViewModel.getAchievementProgress(achievement) / 100)
                        .stroke(achievement.badgeColor, lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !isUnlocked {
                    Text("Progress: \(Int(quizViewModel.getAchievementProgress(achievement)))%")
                        .font(.caption)
                        .foregroundColor(achievement.badgeColor)
                }
            }
            
            Spacer()
            
            if isUnlocked {
                VStack {
                    Text("+\(achievement.pointsReward)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.premiumGold)
                    
                    Text("pts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Compact Button Styles

struct CompactPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(FintechColors.primaryBlue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CompactSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(FintechColors.primaryBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(FintechColors.primaryBlue.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
} 