import SwiftUI
import SwiftData

struct FriendsView: View {
    @EnvironmentObject var vm: FriendsViewModel
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \FoodEntry.date,      order: .reverse) private var foods:    [FoodEntry]

    @State private var selectedTab = 0
    @State private var showProfileSetup = false
    @State private var showAddFriend = false
    @State private var friendUsernameInput = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if !vm.profileCreated {
                        profileSetupBanner
                    }
                    if vm.profileCreated {
                        syncRow
                    }
                    segmentPicker
                    ScrollView {
                        VStack(spacing: 14) {
                            if vm.profileCreated { myProfileCard }
                            if selectedTab == 0 { leaderboardSection }
                            else                { friendsSection     }
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if vm.profileCreated {
                        Button {
                            showAddFriend = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .foregroundStyle(Color.gymGreen)
                                .font(.system(size: 18))
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showProfileSetup = true
                    } label: {
                        Text(FriendsViewModel.avatarEmojis[safe: vm.avatarIndex] ?? "💪")
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showProfileSetup) {
                ProfileSetupView()
                    .environmentObject(vm)
            }
            .sheet(isPresented: $showAddFriend) {
                addFriendSheet
            }
            .task {
                await vm.checkiCloudStatus()
                await vm.loadFriends()
                await vm.loadLeaderboard()
            }
            .onChange(of: selectedTab) { _, tab in
                if tab == 0 { Task { await vm.loadLeaderboard() } }
            }
            .onChange(of: vm.successMessage) { _, msg in
                if msg != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        vm.successMessage = nil
                    }
                }
            }
        }
    }

    // MARK: - My Profile Card
    private var myProfileCard: some View {
        Button { showProfileSetup = true } label: {
            HStack(spacing: 14) {
                Text(FriendsViewModel.avatarEmojis[safe: vm.avatarIndex] ?? "💪")
                    .font(.system(size: 40))
                    .frame(width: 56, height: 56)
                    .background(Color.gymPrimary.opacity(0.12))
                    .cornerRadius(28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("@\(vm.username)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Button {
                        Task { await vm.syncProfileIfNeeded() }
                    } label: {
                        HStack(spacing: 4) {
                            if vm.isSyncing {
                                ProgressView().tint(.white).scaleEffect(0.6)
                            } else {
                                Image(systemName: vm.isProfileSynced ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11))
                            }
                            Text(vm.isProfileSynced ? "Synced" : "Tap to Sync")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(vm.isProfileSynced ? Color(red: 0.0, green: 0.9, blue: 0.7) : Color.gymOrange)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(vm.isProfileSynced ? Color(red: 0.0, green: 0.9, blue: 0.7).opacity(0.12) : Color.gymOrange.opacity(0.15))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(vm.isProfileSynced ? Color.clear : Color.gymOrange.opacity(0.4), lineWidth: 1))
                    }
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(14)
            .background(Color.gymPrimary.opacity(0.06))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gymPrimary.opacity(0.2), lineWidth: 1))
        }
    }

    // MARK: - Profile Setup Banner
    private var profileSetupBanner: some View {
        Button { showProfileSetup = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 20))
                    .foregroundStyle(.gymGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set Up Your Profile")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Create a username to join the leaderboard and add friends.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.system(size: 12))
            }
            .padding(12)
            .background(Color.gymGreen.opacity(0.1))
            .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.gymGreen.opacity(0.2)), alignment: .bottom)
        }
    }

    // MARK: - Sync Row
    private var syncRow: some View {
        HStack(spacing: 10) {
            if let msg = vm.successMessage {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.gymGreen)
                Text(msg)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.gymGreen)
            } else {
                Text("@\(vm.username)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Text("·")
                    .foregroundStyle(.white.opacity(0.2))
                Text("\(vm.friends.count) friend\(vm.friends.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Button {
                Task { await vm.submitThisWeek(sessions: sessions, foods: foods) }
            } label: {
                HStack(spacing: 5) {
                    if vm.isSyncing {
                        ProgressView().tint(.white).scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text("Sync Stats")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(LinearGradient.gymGreenGrad)
                .cornerRadius(20)
            }
            .disabled(vm.isSyncing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.gymCard.opacity(0.6))
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color.white.opacity(0.08)), alignment: .bottom)
    }

    // MARK: - Segment Picker
    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(["Leaderboard", "Friends"], id: \.self) { tab in
                let idx = tab == "Leaderboard" ? 0 : 1
                Button {
                    withAnimation(.spring(response: 0.25)) { selectedTab = idx }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab)
                            .font(.system(size: 14, weight: selectedTab == idx ? .bold : .medium))
                            .foregroundStyle(selectedTab == idx ? .white : .white.opacity(0.4))
                        Rectangle()
                            .fill(selectedTab == idx ? Color.gymPrimary : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.gymCard.opacity(0.4))
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color.white.opacity(0.08)), alignment: .bottom)
    }

    // MARK: - Leaderboard
    private var leaderboardSection: some View {
        VStack(spacing: 10) {
            if vm.isLoading {
                ProgressView().tint(.gymPrimary).padding(.top, 40)
            } else if vm.leaderboard.isEmpty {
                emptyLeaderboardState
            } else {
                ForEach(Array(vm.leaderboard.enumerated()), id: \.element.id) { idx, row in
                    LeaderboardRowCard(rank: idx + 1, row: row, isMe: row.id == vm.userID)
                }
            }
        }
    }

    private var emptyLeaderboardState: some View {
        VStack(spacing: 14) {
            Text("🏆")
                .font(.system(size: 60))
            Text("No leaderboard data yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text("Sync your stats and add friends to compete!")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Friends
    private var friendsSection: some View {
        VStack(spacing: 10) {
            if vm.friends.isEmpty {
                VStack(spacing: 14) {
                    Text("👥")
                        .font(.system(size: 60))
                    Text("No friends yet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Tap + to search for friends by username.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                    Button { showAddFriend = true } label: {
                        Text("Add Friend")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(LinearGradient.gymGreenGrad)
                            .cornerRadius(20)
                    }
                }
                .padding(.vertical, 40)
            } else {
                ForEach(vm.friends) { friend in
                    FriendCard(friend: friend) {
                        Task { await vm.removeFriend(friend) }
                    }
                }
            }
        }
    }

    // MARK: - Add Friend Sheet
    private var addFriendSheet: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    // Your shareable username
                    HStack(spacing: 10) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.gymPrimary)
                        Text("Your username: ")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("@\(vm.username)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.gymPrimary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.gymPrimary.opacity(0.08))
                    .cornerRadius(10)

                    FormCard {
                        HStack(spacing: 10) {
                            Image(systemName: "at").foregroundStyle(.gymGreen)
                            TextField("username (without @)", text: $friendUsernameInput)
                                .foregroundStyle(.white)
                                .tint(.gymGreen)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onSubmit { Task { await vm.searchUser(query: friendUsernameInput) } }
                        }
                    }

                    Button {
                        Task { await vm.searchUser(query: friendUsernameInput) }
                    } label: {
                        HStack {
                            if vm.isSearching { ProgressView().tint(.white).scaleEffect(0.8) }
                            Text(vm.isSearching ? "Searching..." : "Search")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.gymGreenGrad)
                        .cornerRadius(14)
                    }
                    .disabled(friendUsernameInput.count < 2 || vm.isSearching)

                    if !vm.searchResults.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(vm.searchResults) { result in
                                HStack(spacing: 12) {
                                    Text(FriendsViewModel.avatarEmojis[safe: result.avatarIndex] ?? "💪")
                                        .font(.system(size: 28))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(result.displayName)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("@\(result.username)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    Button {
                                        Task {
                                            await vm.addFriend(username: result.username)
                                            showAddFriend = false
                                        }
                                    } label: {
                                        Text("Add")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 16).padding(.vertical, 8)
                                            .background(Color.gymGreen).cornerRadius(20)
                                    }
                                }
                                .padding(14).gymCard()
                            }
                        }
                    }

                    if let err = vm.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.gymYellow)
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(12)
                        .background(Color.gymYellow.opacity(0.1))
                        .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddFriend = false }
                        .foregroundStyle(Color.gymPrimary)
                }
            }
        }
    }
}

// MARK: - Leaderboard Row Card
struct LeaderboardRowCard: View {
    let rank: Int
    let row: LeaderboardRow
    let isMe: Bool

    private var medalEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            if rank <= 3 {
                Text(medalEmoji)
                    .font(.system(size: 28))
                    .frame(width: 36)
            } else {
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 36)
            }

            // Avatar
            Text(FriendsViewModel.avatarEmojis[safe: row.avatarIndex] ?? "💪")
                .font(.system(size: 26))

            // Name & Score
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(row.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    if isMe {
                        Text("YOU")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.gymPrimary)
                            .cornerRadius(4)
                    }
                }
                HStack(spacing: 10) {
                    Label("\(row.weeklyWorkouts) sessions", systemImage: "dumbbell.fill")
                    Label(volumeStr(row.weeklyVolume), systemImage: "scalemass.fill")
                }
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(row.gymRatScore)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(rank == 1 ? Color.gymYellow : rank <= 3 ? Color.gymOrange : Color.gymPrimary)
                Text("pts")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(14)
        .background(
            isMe
            ? AnyView(
                Color.gymPrimary.opacity(0.08)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gymPrimary.opacity(0.3), lineWidth: 1))
              )
            : AnyView(Color.gymCard.cornerRadius(16))
        )
    }

    private func volumeStr(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk kg", v/1000) : "\(Int(v)) kg"
    }
}

// MARK: - Friend Card
struct FriendCard: View {
    let friend: FriendRow
    let onRemove: () -> Void

    @State private var showConfirm = false

    var body: some View {
        HStack(spacing: 14) {
            Text(FriendsViewModel.avatarEmojis[safe: friend.avatarIndex] ?? "💪")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 3) {
                Text(friend.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text("@\(friend.username)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Button { showConfirm = true } label: {
                Image(systemName: "person.fill.xmark")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.gymRed.opacity(0.7))
                    .padding(8)
                    .background(Color.gymRed.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .gymCard()
        .confirmationDialog("Remove \(friend.displayName)?", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Remove Friend", role: .destructive) { onRemove() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
