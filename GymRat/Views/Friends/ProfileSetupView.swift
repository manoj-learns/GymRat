import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var vm: FriendsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var username = ""
    @State private var selectedAvatar = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar picker
                        VStack(spacing: 14) {
                            Text(FriendsViewModel.avatarEmojis[safe: selectedAvatar] ?? "💪")
                                .font(.system(size: 72))

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                                ForEach(Array(FriendsViewModel.avatarEmojis.enumerated()), id: \.offset) { idx, emoji in
                                    Button { selectedAvatar = idx } label: {
                                        Text(emoji)
                                            .font(.system(size: 30))
                                            .padding(8)
                                            .background(selectedAvatar == idx ? Color.gymPrimary.opacity(0.2) : Color.gymCard)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedAvatar == idx ? Color.gymPrimary : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)

                        FormCard {
                            GymTextField(label: "Display Name", text: $displayName, placeholder: "e.g., Manoj P")
                            Divider().background(Color.white.opacity(0.08))
                            GymTextField(label: "Username", text: $username, placeholder: "e.g., manoj_lifts")
                        }

                        Text("Your username is how friends find you. Choose something unique — it can't be changed later.")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)

                        if let err = vm.errorMessage {
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundStyle(.gymRed)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task {
                                await vm.saveProfile(
                                    displayName: displayName,
                                    username: username,
                                    avatarIndex: selectedAvatar
                                )
                                if vm.profileCreated { dismiss() }
                            }
                        } label: {
                            HStack {
                                if vm.isLoading {
                                    ProgressView().tint(.white).scaleEffect(0.8)
                                }
                                Text(vm.isLoading ? "Saving..." : "Create Profile")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSave ? LinearGradient.gymGreenGrad : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                        }
                        .disabled(!canSave || vm.isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle(vm.profileCreated ? "Edit Profile" : "Create Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.gymPrimary)
                }
            }
            .onAppear {
                displayName   = vm.displayName
                username      = vm.username
                selectedAvatar = vm.avatarIndex
            }
        }
    }

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        username.trimmingCharacters(in: .whitespaces).count >= 3
    }
}
