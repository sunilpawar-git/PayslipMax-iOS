import SwiftUI

// MARK: - Tip Streak Widget

struct TipStreakWidget: View {
    let currentStreak: Int
    let longestStreak: Int
    let totalTipsViewed: Int
    let achievementBadges: [TipAchievement]
    let weeklyGoal: Int
    let weeklyProgress: Int
    
    @State private var animateStreak = false
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection
            
            // Main Stats
            statsSection
            
            // Weekly Progress
            weeklyProgressSection
            
            // Achievement Badges
            if !achievementBadges.isEmpty {
                achievementSection
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animateStreak = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                animateProgress = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.orange)
                    .scaleEffect(animateStreak ? 1.0 : 0.8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatCount(3, autoreverses: true), value: animateStreak)
                
                Text("Learning Streak")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Streak counter
            streakCounter
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            // Current Streak
            statItem(
                title: "Current",
                value: "\(currentStreak)",
                subtitle: "days",
                color: .orange,
                icon: "flame.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            // Longest Streak
            statItem(
                title: "Best",
                value: "\(longestStreak)",
                subtitle: "days",
                color: .blue,
                icon: "trophy.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            // Total Tips
            statItem(
                title: "Total",
                value: "\(totalTipsViewed)",
                subtitle: "tips",
                color: .green,
                icon: "lightbulb.fill"
            )
        }
    }
    
    // MARK: - Weekly Progress Section
    
    private var weeklyProgressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Weekly Goal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(weeklyProgress)/\(weeklyGoal)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Progress Bar
            progressBar
            
            // Progress Dots
            progressDots
        }
    }
    
    // MARK: - Achievement Section
    
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Achievements")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievementBadges.prefix(3), id: \.id) { achievement in
                        achievementBadge(achievement)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    // MARK: - UI Components
    
    private var streakCounter: some View {
        HStack(spacing: 4) {
            Text("\(currentStreak)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .scaleEffect(animateStreak ? 1.1 : 1.0)
            
            Text("day\(currentStreak == 1 ? "" : "s")")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private func statItem(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .scaleEffect(animateProgress ? 1.0 : 0.8)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 6)
                    .fill(progressGradient)
                    .frame(width: animateProgress ? progressWidth(in: geometry) : 0, height: 8)
                    .animation(.easeInOut(duration: 1.0), value: animateProgress)
            }
        }
        .frame(height: 8)
    }
    
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(1...weeklyGoal, id: \.self) { day in
                Circle()
                    .fill(day <= weeklyProgress ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(day <= weeklyProgress && animateProgress ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(day) * 0.1), value: animateProgress)
            }
        }
    }
    
    private func achievementBadge(_ achievement: TipAchievement) -> some View {
        VStack(spacing: 4) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(achievement.color)
                .frame(width: 40, height: 40)
                .background(achievement.color.opacity(0.1))
                .clipShape(Circle())
            
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 50)
        }
    }
    
    // MARK: - Computed Properties
    
    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        let progress = min(Double(weeklyProgress) / Double(weeklyGoal), 1.0)
        return geometry.size.width * progress
    }
}

// MARK: - Supporting Models

struct TipAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let unlockedDate: Date
    
    static let sampleAchievements = [
        TipAchievement(
            title: "First Step",
            description: "Viewed your first investment tip",
            iconName: "star.fill",
            color: .yellow,
            unlockedDate: Date().addingTimeInterval(-86400 * 2)
        ),
        TipAchievement(
            title: "Consistent",
            description: "3-day learning streak",
            iconName: "flame.fill",
            color: .orange,
            unlockedDate: Date().addingTimeInterval(-86400)
        ),
        TipAchievement(
            title: "Engaged",
            description: "Liked 5 tips",
            iconName: "heart.fill",
            color: .red,
            unlockedDate: Date()
        )
    ]
}

// MARK: - Preview

struct TipStreakWidget_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TipStreakWidget(
                currentStreak: 3,
                longestStreak: 7,
                totalTipsViewed: 15,
                achievementBadges: TipAchievement.sampleAchievements,
                weeklyGoal: 7,
                weeklyProgress: 4
            )
            
            TipStreakWidget(
                currentStreak: 0,
                longestStreak: 2,
                totalTipsViewed: 5,
                achievementBadges: [],
                weeklyGoal: 7,
                weeklyProgress: 0
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 