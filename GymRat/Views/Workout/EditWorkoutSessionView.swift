import SwiftUI
import SwiftData

struct EditWorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @State private var name: String
    @State private var notes: String
    @State private var date: Date
    @State private var setToEdit: WorkoutSet?

    init(session: WorkoutSession) {
        self.session = session
        _name  = State(initialValue: session.name)
        _notes = State(initialValue: session.notes)
        _date  = State(initialValue: session.date)
    }

    var groupedSets: [(exercise: String, sets: [WorkoutSet])] {
        let dict = Dictionary(grouping: session.sets) { $0.exerciseName }
        return dict.keys.sorted().map { key in (exercise: key, sets: dict[key]!.sorted { $0.setNumber < $1.setNumber }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Session info
                        FormCard {
                            GymTextField(label: "Session Name", text: $name, placeholder: "e.g., Chest Day")
                            Divider().background(Color.white.opacity(0.08))
                            HStack {
                                Text("Date")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 110, alignment: .leading)
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .tint(.gymPrimary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
                            Divider().background(Color.white.opacity(0.08))
                            GymTextField(label: "Notes", text: $notes, placeholder: "Optional notes")
                        }

                        // Sets per exercise
                        if !groupedSets.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sets")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)

                                ForEach(groupedSets, id: \.exercise) { group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(group.exercise)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Text("\(group.sets.count) sets")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.white.opacity(0.4))
                                        }

                                        ForEach(group.sets) { set in
                                            HStack(spacing: 10) {
                                                Text("Set \(set.setNumber)")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.white.opacity(0.4))
                                                    .frame(width: 48, alignment: .leading)

                                                Text("\(set.reps) reps × \(String(format: "%.1f", set.weight)) kg")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(.white)

                                                Spacer()

                                                Button { setToEdit = set } label: {
                                                    Image(systemName: "pencil.circle")
                                                        .font(.system(size: 18))
                                                        .foregroundStyle(.gymPrimary)
                                                }
                                                Button {
                                                    deleteSet(set)
                                                } label: {
                                                    Image(systemName: "trash.circle")
                                                        .font(.system(size: 18))
                                                        .foregroundStyle(.gymRed.opacity(0.7))
                                                }
                                            }
                                            .padding(.horizontal, 4)
                                        }
                                    }
                                    .padding(14)
                                    .gymCard()
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.gymPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSession() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.gymPrimary)
                }
            }
            .sheet(item: $setToEdit) { set in
                EditSetView(workoutSet: set)
            }
        }
    }

    private func saveSession() {
        session.name  = name
        session.notes = notes
        session.date  = date
        dismiss()
    }

    private func deleteSet(_ set: WorkoutSet) {
        session.sets.removeAll { $0.id == set.id }
        modelContext.delete(set)
    }
}

// MARK: - Edit Individual Set
struct EditSetView: View {
    @Environment(\.dismiss) private var dismiss
    let workoutSet: WorkoutSet

    @State private var reps: String
    @State private var weight: String

    init(workoutSet: WorkoutSet) {
        self.workoutSet = workoutSet
        _reps   = State(initialValue: "\(workoutSet.reps)")
        _weight = State(initialValue: String(format: "%.1f", workoutSet.weight))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    // Exercise name header
                    VStack(spacing: 6) {
                        Text(workoutSet.exerciseName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Set \(workoutSet.setNumber)")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 20)

                    HStack(spacing: 16) {
                        InputField(label: "Reps", value: $reps, unit: "")
                        InputField(label: "Weight", value: $weight, unit: "kg")
                    }
                    .padding(.horizontal)

                    Button { saveSet() } label: {
                        Text("Save Set")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.gymCyan)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.gymPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveSet() {
        workoutSet.reps   = Int(reps) ?? workoutSet.reps
        workoutSet.weight = Double(weight) ?? workoutSet.weight
        dismiss()
    }
}
