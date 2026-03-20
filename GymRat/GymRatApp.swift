import SwiftUI
import SwiftData

@main
struct GymRatApp: App {
    @StateObject private var friendsVM = FriendsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    WorkoutSession.self,
                    WorkoutSet.self,
                    FoodEntry.self,
                    SleepEntry.self
                ])
                .environmentObject(friendsVM)
                .preferredColorScheme(.dark)
                .task { await friendsVM.checkiCloudStatus() }
        }
    }
}
