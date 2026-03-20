import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var showingActiveWorkout = false
    @State private var activeSession: WorkoutSession?
    @State private var sessionToEdit: WorkoutSession?

    private let calendar = Calendar.current

    var thisWeekSessions: [WorkoutSession] {
        sessions.filter {
            calendar.dateInterval(of: .weekOfYear, for: Date())?.contains($0.date) == true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        weeklyStatsBar
                        startWorkoutButton
                        recentSessionsList
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(item: $activeSession) { session in
                ActiveWorkoutView(session: session)
            }
            .sheet(item: $sessionToEdit) { session in
                EditWorkoutSessionView(session: session)
            }
        }
    }

    // MARK: - Weekly Stats
    private var weeklyStatsBar: some View {
        HStack(spacing: 0) {
            WeeklyStatItem(value: "\(thisWeekSessions.count)", label: "Workouts", color: .gymPrimary)
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            WeeklyStatItem(
                value: totalVolumeStr,
                label: "Total Volume",
                color: .gymOrange
            )
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            WeeklyStatItem(
                value: "\(thisWeekSessions.flatMap { $0.sets }.count)",
                label: "Total Sets",
                color: .gymGreen
            )
        }
        .padding()
        .gymCard()
    }

    private var totalVolumeStr: String {
        let total = thisWeekSessions.reduce(0) { $0 + $1.totalVolume }
        if total >= 1000 { return String(format: "%.1fk", total / 1000) }
        return "\(Int(total))"
    }

    // MARK: - Start Workout
    private var startWorkoutButton: some View {
        Button {
            let session = WorkoutSession(name: "Workout \(sessions.count + 1)")
            modelContext.insert(session)
            activeSession = session
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start New Workout")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Tap to begin your session")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(18)
            .background(LinearGradient.gymCyan)
            .cornerRadius(16)
            .shadow(color: .gymPrimary.opacity(0.4), radius: 12, y: 4)
        }
    }

    // MARK: - Recent Sessions
    private var recentSessionsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("History")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            if sessions.isEmpty {
                EmptyStateRow(text: "No workouts yet. Start your first session!")
            } else {
                HStack {
                    Spacer()
                    Label("Swipe to edit or delete", systemImage: "hand.point.left")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.25))
                }
                ForEach(sessions.prefix(20)) { session in
                    NavigationLink(destination: WorkoutDetailView(session: session)) {
                        WorkoutSessionCard(session: session)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { deleteSession(session) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button { sessionToEdit = session } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.gymOrange)
                    }
                }
            }
        }
    }

    private func deleteSession(_ session: WorkoutSession) {
        modelContext.delete(session)
    }
}

// MARK: - Weekly Stat Item
struct WeeklyStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session Card
struct WorkoutSessionCard: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.gymCyan)
                    .frame(width: 50, height: 50)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.name.isEmpty ? "Workout" : session.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(session.date, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))

                HStack(spacing: 12) {
                    Label("\(session.exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                    Label("\(session.setCount) sets", systemImage: "list.number")
                }
                .font(.system(size: 11))
                .foregroundStyle(.gymPrimary.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if session.totalVolume > 0 {
                    Text(volumeString(session.totalVolume))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.gymOrange)
                    Text("volume")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                if session.duration > 0 {
                    Text(durationString(session.duration))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(14)
        .gymCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func volumeString(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk kg", v/1000) : "\(Int(v)) kg"
    }
    private func durationString(_ d: TimeInterval) -> String {
        let min = Int(d / 60)
        return min >= 60 ? "\(min/60)h \(min%60)m" : "\(min)m"
    }
}

// MARK: - Workout Detail
struct WorkoutDetailView: View {
    let session: WorkoutSession

    var groupedSets: [String: [WorkoutSet]] {
        Dictionary(grouping: session.sets) { $0.exerciseName }
    }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Stats
                    HStack(spacing: 0) {
                        WeeklyStatItem(value: "\(session.exerciseCount)", label: "Exercises", color: .gymPrimary)
                        WeeklyStatItem(value: "\(session.setCount)", label: "Sets", color: .gymOrange)
                        WeeklyStatItem(value: volumeStr, label: "Volume", color: .gymGreen)
                    }
                    .padding()
                    .gymCard()
                    .padding(.horizontal)

                    // Sets by exercise
                    ForEach(groupedSets.keys.sorted(), id: \.self) { exercise in
                        let sets = groupedSets[exercise] ?? []
                        VStack(alignment: .leading, spacing: 10) {
                            Text(exercise)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber })) { s in
                                HStack {
                                    Text("Set \(s.setNumber)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .frame(width: 50, alignment: .leading)
                                    Text("\(s.reps) reps")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(String(format: "%.1f", s.weight)) kg")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.gymPrimary)
                                }
                            }
                        }
                        .padding(14)
                        .gymCard()
                        .padding(.horizontal)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle(session.name.isEmpty ? "Workout" : session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.gymBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var volumeStr: String {
        let v = session.totalVolume
        return v >= 1000 ? String(format: "%.1fk", v/1000) : "\(Int(v))"
    }
}
