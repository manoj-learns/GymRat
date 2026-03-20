import Foundation
import SwiftData

@MainActor
class FriendsViewModel: ObservableObject {
    // MARK: - State
    @Published var firebaseConfigured = false
    @Published var isProfileSynced = false
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Profile
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var avatarIndex: Int = 0
    @Published var userID: String = ""
    @Published var profileCreated = false

    // Social
    @Published var friends: [FriendRow] = []
    @Published var leaderboard: [LeaderboardRow] = []
    @Published var searchResults: [FriendRow] = []
    @Published var isSearching = false

    // Persistence
    private let defaults = UserDefaults.standard

    init() {
        displayName  = defaults.string(forKey: "gr_displayName") ?? ""
        username     = defaults.string(forKey: "gr_username") ?? ""
        avatarIndex  = defaults.integer(forKey: "gr_avatarIndex")
        userID       = defaults.string(forKey: "gr_userID") ?? ""
        profileCreated = !username.isEmpty
    }

    // MARK: - Firebase Status
    func checkiCloudStatus() async {
        // Generate a local user ID if not set
        if userID.isEmpty {
            userID = UUID().uuidString
            defaults.set(userID, forKey: "gr_userID")
        }
        await checkFirebaseStatus()
    }

    func checkFirebaseStatus() async {
        firebaseConfigured = await FirebaseService.shared.isConfigured
    }

    func syncProfileIfNeeded() async {
        await checkFirebaseStatus()
        guard profileCreated, !userID.isEmpty else {
            errorMessage = "Create a profile first in the Friends tab."
            return
        }
        guard firebaseConfigured else {
            errorMessage = "Add your Firebase Project ID in Settings first."
            return
        }
        do {
            try await FirebaseService.shared.createOrUpdateUser(
                userId: userID,
                displayName: displayName,
                username: username,
                avatarIndex: avatarIndex
            )
            isProfileSynced = true
            successMessage = "Profile synced! Friends can now find you @\(username)."
        } catch {
            isProfileSynced = false
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Profile
    func saveProfile(displayName: String, username: String, avatarIndex: Int) async {
        guard !displayName.isEmpty, !username.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            await checkFirebaseStatus()
            self.displayName  = displayName
            self.username     = username.lowercased()
            self.avatarIndex  = avatarIndex
            self.profileCreated = true
            defaults.set(self.displayName, forKey: "gr_displayName")
            defaults.set(self.username,    forKey: "gr_username")
            defaults.set(self.avatarIndex, forKey: "gr_avatarIndex")
            if firebaseConfigured {
                try await FirebaseService.shared.createOrUpdateUser(
                    userId: userID,
                    displayName: self.displayName,
                    username: self.username,
                    avatarIndex: self.avatarIndex
                )
                isProfileSynced = true
                successMessage = "Profile saved & synced! Friends can find you @\(self.username)."
            } else {
                isProfileSynced = false
                successMessage = "Profile saved locally. Add Firebase Project ID in Settings to go online."
            }
        } catch {
            self.displayName  = displayName
            self.username     = username.lowercased()
            self.avatarIndex  = avatarIndex
            self.profileCreated = true
            defaults.set(self.displayName, forKey: "gr_displayName")
            defaults.set(self.username,    forKey: "gr_username")
            defaults.set(self.avatarIndex, forKey: "gr_avatarIndex")
            isProfileSynced = false
            successMessage = "Profile saved locally. Tap Sync to upload to Firebase."
        }
    }

    // MARK: - Leaderboard
    func loadLeaderboard() async {
        guard firebaseConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let friendIDs = friends.map { $0.id } + [userID]
            var rows = try await FirebaseService.shared.fetchLeaderboard(friendUserIds: friendIDs)
            rows.sort { $0.gymRatScore > $1.gymRatScore }
            leaderboard = rows
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Submit This Week
    func submitThisWeek(sessions: [WorkoutSession], foods: [FoodEntry]) async {
        guard profileCreated else { return }
        await checkFirebaseStatus()
        guard firebaseConfigured else {
            errorMessage = "Add your Firebase Project ID in Settings to sync stats."
            return
        }
        isSyncing = true
        defer { isSyncing = false }

        let cal = Calendar.current
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: Date())

        let weekSessions = sessions.filter { thisWeek?.contains($0.date) == true }
        let weekFoods    = foods.filter    { thisWeek?.contains($0.date) == true }

        let totalVolume   = weekSessions.reduce(0) { $0 + $1.totalVolume }
        let totalWorkouts = weekSessions.count
        let totalCalories = weekFoods.reduce(0) { $0 + $1.calories }

        do {
            try await FirebaseService.shared.submitWeeklyStats(
                userId: userID,
                displayName: displayName,
                username: username,
                avatarIndex: avatarIndex,
                volume: totalVolume,
                workouts: totalWorkouts,
                calories: totalCalories
            )
            successMessage = "Stats synced!"
            await loadLeaderboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Friends
    func loadFriends() async {
        guard firebaseConfigured, !userID.isEmpty else { return }
        do {
            friends = try await FirebaseService.shared.fetchFriends(myUserId: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addFriend(username: String) async {
        guard firebaseConfigured else {
            errorMessage = "Add your Firebase Project ID in Settings to use friends."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            guard let result = try await FirebaseService.shared.searchUser(username: username) else {
                errorMessage = "User not found."
                return
            }
            try await FirebaseService.shared.addFriend(
                myUserId: userID,
                friendUserId: result.userId,
                friendName: result.displayName,
                friendUsername: result.username,
                friendAvatar: result.avatarIndex
            )
            successMessage = "Friend added!"
            await loadFriends()
            await loadLeaderboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(_ friend: FriendRow) async {
        guard firebaseConfigured else { return }
        do {
            try await FirebaseService.shared.removeFriend(myUserId: userID, friendUserId: friend.id)
            friends.removeAll { $0.id == friend.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchUser(query: String) async {
        guard firebaseConfigured else {
            errorMessage = "Firebase not configured. Add your Project ID in Settings."
            searchResults = []
            return
        }
        let cleanQuery = query.hasPrefix("@") ? String(query.dropFirst()) : query
        guard cleanQuery.count >= 2 else { searchResults = []; return }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            if let result = try await FirebaseService.shared.searchUser(username: cleanQuery) {
                searchResults = [FriendRow(
                    id:          result.userId,
                    displayName: result.displayName,
                    username:    result.username,
                    avatarIndex: result.avatarIndex
                )]
            } else {
                searchResults = []
                errorMessage = "No user found with @\(cleanQuery.lowercased()). Make sure they've created a profile and tapped Sync on the Friends tab."
            }
        } catch {
            searchResults = []
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers
    static let avatarEmojis = ["💪", "🏋️", "🔥", "⚡️", "🦁", "🐺", "🚀", "🏆", "🎯", "💥"]
}
