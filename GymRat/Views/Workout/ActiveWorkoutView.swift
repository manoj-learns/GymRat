import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @State private var showExercisePicker = false
    @State private var selectedExercise: Exercise?
    @State private var currentExercise: Exercise?

    // Set entry state
    @State private var reps: String = "10"
    @State private var weight: String = "20"
    @State private var setGroups: [SetGroup] = []

    @State private var showFinishAlert = false
    @State private var workoutName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    workoutHeader
                    Divider().background(Color.white.opacity(0.08))

                    ScrollView {
                        VStack(spacing: 16) {
                            // Current exercise entry
                            exerciseEntryCard
                            // Logged sets
                            if !setGroups.isEmpty {
                                loggedSetsSection
                            }
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showExercisePicker, onDismiss: {
                if let ex = selectedExercise { currentExercise = ex }
            }) {
                ExercisePickerView(selectedExercise: $selectedExercise)
            }
            .alert("Finish Workout?", isPresented: $showFinishAlert) {
                Button("Finish", role: .destructive) { finishWorkout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your workout will be saved with \(setGroups.flatMap { $0.sets }.count) sets logged.")
            }
        }
    }

    // MARK: - Workout Header
    private var workoutHeader: some View {
        HStack {
            Button { showFinishAlert = true } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Text("Active Workout")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            Button { showFinishAlert = true } label: {
                Text("Finish")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(LinearGradient.gymGreenGrad)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gymCard)
    }

    // MARK: - Exercise Entry Card
    private var exerciseEntryCard: some View {
        VStack(spacing: 14) {
            // Exercise selector
            Button { showExercisePicker = true } label: {
                HStack {
                    if let ex = currentExercise {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ex.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                            Text(ex.category.rawValue + " · " + ex.primaryMuscles.first!)
                                .font(.system(size: 12))
                                .foregroundStyle(ex.category.color)
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.gymPrimary)
                            Text("Select Exercise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.gymPrimary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(16)
                .background(Color.gymCard2)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(currentExercise == nil ? Color.gymPrimary.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                )
            }

            if currentExercise != nil {
                // Rep & Weight inputs
                HStack(spacing: 12) {
                    InputField(label: "Reps", value: $reps, unit: "")
                    InputField(label: "Weight", value: $weight, unit: "kg")
                }

                // Previous best hint
                if let best = bestPrevious(for: currentExercise?.name ?? "") {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                        Text("Best: \(best.reps) reps × \(String(format: "%.1f", best.weight)) kg")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                // Log Set button
                Button { logSet() } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Log Set")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.gymCyan)
                    .cornerRadius(14)
                    .shadow(color: .gymPrimary.opacity(0.3), radius: 8, y: 3)
                }
            }
        }
        .padding(16)
        .background(Color.gymCard)
        .cornerRadius(16)
    }

    // MARK: - Logged Sets
    private var loggedSetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logged Sets")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            ForEach($setGroups) { $group in
                SetGroupCard(group: $group, onDelete: {
                    setGroups.removeAll { $0.id == group.id }
                })
            }
        }
    }

    // MARK: - Actions
    private func logSet() {
        guard let ex = currentExercise,
              let repsInt = Int(reps),
              let weightDouble = Double(weight),
              repsInt > 0 else { return }

        let setNumber = (setGroups.first(where: { $0.exerciseName == ex.name })?.sets.count ?? 0) + 1
        let newSet = WorkoutSet(
            exerciseName: ex.name,
            exerciseCategory: ex.category.rawValue,
            reps: repsInt,
            weight: weightDouble,
            setNumber: setNumber
        )
        modelContext.insert(newSet)
        newSet.session = session
        session.sets.append(newSet)

        // Update local display
        if let idx = setGroups.firstIndex(where: { $0.exerciseName == ex.name }) {
            setGroups[idx].sets.append(SetEntry(reps: repsInt, weight: weightDouble, setNumber: setNumber))
        } else {
            setGroups.append(SetGroup(exerciseName: ex.name, category: ex.category, sets: [
                SetEntry(reps: repsInt, weight: weightDouble, setNumber: setNumber)
            ]))
        }
    }

    private func finishWorkout() {
        if session.name.isEmpty || session.name.hasPrefix("Workout ") {
            let topMuscle = session.sets.first?.exerciseCategory ?? "Full Body"
            session.name = "\(topMuscle) Day"
        }
        dismiss()
    }

    private func bestPrevious(for exercise: String) -> SetEntry? {
        // Look in current session for best set
        setGroups.first(where: { $0.exerciseName == exercise })?.sets.max(by: { $0.weight < $1.weight })
    }
}

// MARK: - Input Field
struct InputField: View {
    let label: String
    @Binding var value: String
    let unit: String

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            HStack(spacing: 4) {
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tint(.gymPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.gymCard2)
        .cornerRadius(12)
    }
}

// MARK: - Set Group Card
struct SetGroupCard: View {
    @Binding var group: SetGroup
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: group.category.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(group.category.color)
                    Text(group.exerciseName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.gymRed.opacity(0.7))
                }
            }

            ForEach(group.sets) { entry in
                HStack {
                    Text("Set \(entry.setNumber)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(width: 50, alignment: .leading)
                    Text("\(entry.reps) reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%.1f kg", entry.weight))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.gymPrimary)
                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))
                    Text(String(format: "%.0f kg vol", Double(entry.reps) * entry.weight))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(14)
        .background(Color.gymCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(group.category.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Local State Models
struct SetGroup: Identifiable {
    let id = UUID()
    var exerciseName: String
    var category: ExerciseCategory
    var sets: [SetEntry]
}

struct SetEntry: Identifiable {
    let id = UUID()
    let reps: Int
    let weight: Double
    let setNumber: Int
}
