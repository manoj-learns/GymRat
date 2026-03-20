import Foundation

// MARK: - Social Data Models

struct LeaderboardRow: Identifiable {
    let id: String
    let displayName: String
    let username: String
    let weeklyVolume: Double
    let weeklyWorkouts: Int
    let weeklyCalories: Double
    let avatarIndex: Int

    var gymRatScore: Int {
        let volScore = Int(weeklyVolume * 0.5)
        let wrkScore = weeklyWorkouts * 200
        let calScore = Int(weeklyCalories / 100)
        return volScore + wrkScore + calScore
    }
}

struct FriendRow: Identifiable {
    let id: String
    let displayName: String
    let username: String
    let avatarIndex: Int
    var weeklyVolume: Double = 0
    var weeklyWorkouts: Int = 0
}
