import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("anthropic_api_key") private var apiKey: String = ""
    @AppStorage("firebase_project_id") private var firebaseProjectId: String = ""
    @AppStorage("calorie_goal") private var calorieGoal: String = "2200"
    @AppStorage("protein_goal") private var proteinGoal: String = "150"
    @AppStorage("sleep_goal") private var sleepGoal: String = "8"
    @AppStorage("user_name") private var userName: String = ""

    @State private var showApiKeyInfo = false
    @State private var showFirebaseInfo = false
    @State private var tempApiKey: String = ""
    @State private var tempProjectId: String = ""
    @State private var isApiKeySaved = false
    @State private var isProjectIdSaved = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile
                        profileSection

                        // AI Configuration
                        aiSection

                        // Firebase
                        firebaseSection

                        // Goals
                        goalsSection

                        // About
                        aboutSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.gymPrimary)
                }
            }
            .onAppear {
                tempApiKey = apiKey
                tempProjectId = firebaseProjectId
            }
        }
    }

    // MARK: - Profile
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Profile", icon: "person.fill", color: .gymPrimary)
            FormCard {
                GymTextField(label: "Your Name", text: $userName, placeholder: "e.g., Manoj")
            }
        }
    }

    // MARK: - AI
    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "AI Configuration", icon: "brain.head.profile", color: .gymGreen)
                Spacer()
                Button {
                    showApiKeyInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.gymPrimary)
                }
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: apiKey.isEmpty ? "key.slash" : "key.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(apiKey.isEmpty ? Color.gymRed : Color.gymGreen)

                    Text(apiKey.isEmpty ? "No API Key" : "API Key Configured")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(apiKey.isEmpty ? Color.gymRed : Color.gymGreen)
                    Spacer()
                    if !apiKey.isEmpty {
                        Text("sk-ant-***\(String(apiKey.suffix(6)))")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(14)
                .gymCard()

                SecureField("Enter Claude API Key", text: $tempApiKey)
                    .foregroundStyle(.white)
                    .tint(.gymGreen)
                    .padding(14)
                    .gymCard()

                Button {
                    apiKey = tempApiKey
                    isApiKeySaved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isApiKeySaved = false
                    }
                } label: {
                    HStack {
                        if isApiKeySaved {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isApiKeySaved ? "Saved!" : "Save API Key")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isApiKeySaved ? AnyShapeStyle(Color.gymGreen) : AnyShapeStyle(LinearGradient.gymGreenGrad))
                    .cornerRadius(12)
                }
                .disabled(tempApiKey.isEmpty)
                .opacity(tempApiKey.isEmpty ? 0.5 : 1)

                Text("Your API key is stored locally on your device and never shared.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
            }
        }
        .alert("About Claude API", isPresented: $showApiKeyInfo) {
            Button("OK") {}
        } message: {
            Text("GymRat uses Claude (by Anthropic) for food recognition and AI insights.\n\nGet your API key from console.anthropic.com\n\nWithout an API key, AI features will use offline estimates.")
        }
    }

    // MARK: - Firebase
    private var firebaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Firebase (Friends & Leaderboard)", icon: "person.2.fill", color: Color(red: 0.0, green: 0.9, blue: 0.7))
                Spacer()
                Button { showFirebaseInfo = true } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.gymPrimary)
                }
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: firebaseProjectId.isEmpty ? "wifi.slash" : "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(firebaseProjectId.isEmpty ? Color.gymRed : Color(red: 0.0, green: 0.9, blue: 0.7))

                    Text(firebaseProjectId.isEmpty ? "Not Connected" : "Firebase Connected")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(firebaseProjectId.isEmpty ? Color.gymRed : Color(red: 0.0, green: 0.9, blue: 0.7))
                    Spacer()
                    if !firebaseProjectId.isEmpty {
                        Text(firebaseProjectId)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .padding(14)
                .gymCard()

                TextField("Firebase Project ID", text: $tempProjectId)
                    .foregroundStyle(.white)
                    .tint(Color(red: 0.0, green: 0.9, blue: 0.7))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(14)
                    .gymCard()

                Button {
                    firebaseProjectId = tempProjectId
                    UserDefaults.standard.set(tempProjectId, forKey: "firebase_project_id")
                    isProjectIdSaved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isProjectIdSaved = false
                    }
                } label: {
                    HStack {
                        if isProjectIdSaved {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isProjectIdSaved ? "Saved!" : "Save Project ID")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isProjectIdSaved ? AnyShapeStyle(Color(red: 0.0, green: 0.9, blue: 0.7)) : AnyShapeStyle(LinearGradient(colors: [Color(red: 0.0, green: 0.9, blue: 0.7), Color(red: 0.0, green: 0.65, blue: 0.55)], startPoint: .leading, endPoint: .trailing)))
                    .cornerRadius(12)
                }
                .disabled(tempProjectId.isEmpty)
                .opacity(tempProjectId.isEmpty ? 0.5 : 1)

                Text("Create a free Firebase project at console.firebase.google.com, enable Firestore in test mode, and paste your Project ID above.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
            }
        }
        .alert("Firebase Setup", isPresented: $showFirebaseInfo) {
            Button("OK") {}
        } message: {
            Text("Firebase powers the Friends & Leaderboard features.\n\n1. Go to console.firebase.google.com\n2. Create a new project\n3. Enable Firestore Database in test mode\n4. Copy your Project ID (found in Project Settings)\n5. Paste it above\n\nFree tier supports up to 50,000 reads/day.")
        }
    }

    // MARK: - Goals
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Daily Goals", icon: "target", color: .gymOrange)
            FormCard {
                GymTextField(label: "Calories (kcal)", text: $calorieGoal, placeholder: "2200", keyboardType: .numberPad)
                Divider().background(Color.white.opacity(0.08))
                GymTextField(label: "Protein (g)", text: $proteinGoal, placeholder: "150", keyboardType: .numberPad)
                Divider().background(Color.white.opacity(0.08))
                GymTextField(label: "Sleep (hours)", text: $sleepGoal, placeholder: "8", keyboardType: .decimalPad)
            }
        }
    }

    // MARK: - About
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "About", icon: "info.circle.fill", color: .gymPrimary)
            FormCard {
                HStack {
                    Text("GymRat")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("Version 1.0")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Divider().background(Color.white.opacity(0.08))
                HStack {
                    Text("AI Model")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("Claude Opus 4")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.gymGreen)
                }
                Divider().background(Color.white.opacity(0.08))
                HStack {
                    Text("Built with")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("SwiftUI · SwiftData")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.gymPrimary)
                }
            }
        }
    }
}
