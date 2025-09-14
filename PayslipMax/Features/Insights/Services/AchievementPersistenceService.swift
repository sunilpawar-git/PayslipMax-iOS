import Foundation

/// Service responsible for persisting achievement progress data
protocol AchievementPersistenceServiceProtocol {
    func loadUserProgress() -> UserGamificationProgress?
    func saveUserProgress(_ progress: UserGamificationProgress)
    func resetProgress()
}

/// Service responsible for persisting achievement progress data
class AchievementPersistenceService: AchievementPersistenceServiceProtocol {

    private let userDefaultsKey = "userGamificationProgress"

    /// Loads user progress from persistent storage
    func loadUserProgress() -> UserGamificationProgress? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(UserGamificationProgress.self, from: data)
        } catch {
            print("Error decoding user progress: \(error)")
            return nil
        }
    }

    /// Saves user progress to persistent storage
    func saveUserProgress(_ progress: UserGamificationProgress) {
        do {
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error encoding user progress: \(error)")
        }
    }

    /// Resets all progress data (for development/testing purposes)
    func resetProgress() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
