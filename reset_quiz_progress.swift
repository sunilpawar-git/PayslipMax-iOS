import Foundation

// Temporary script to reset quiz progress to 0 stars
// This simulates what the reset button would do in the app

// Clear UserDefaults key used by AchievementService
UserDefaults.standard.removeObject(forKey: "userGamificationProgress")

print("✅ Quiz progress reset successfully!")
print("📊 Stars are now back to 0")
print("🎯 You can now test the quiz system from scratch") 