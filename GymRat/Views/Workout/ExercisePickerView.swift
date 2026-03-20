import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercise: Exercise?

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil

    var filteredExercises: [Exercise] {
        var list = ExerciseLibrary.all
        if let cat = selectedCategory { list = list.filter { $0.category == cat } }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.primaryMuscles.joined().localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("Search exercises...", text: $searchText)
                            .foregroundStyle(.white)
                            .tint(.gymPrimary)
                    }
                    .padding(12)
                    .background(Color.gymCard)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                label: "All",
                                color: .gymPrimary,
                                isSelected: selectedCategory == nil
                            ) { selectedCategory = nil }

                            ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                                CategoryChip(
                                    label: cat.rawValue,
                                    color: cat.color,
                                    isSelected: selectedCategory == cat
                                ) { selectedCategory = cat }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }

                    // Exercise list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExercises) { exercise in
                                Button {
                                    selectedExercise = exercise
                                    dismiss()
                                } label: {
                                    ExerciseRow(exercise: exercise)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Choose Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.gymPrimary)
                }
            }
        }
    }
}

struct CategoryChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.gymCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(exercise.category.color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: exercise.category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(exercise.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(exercise.primaryMuscles.joined(separator: " · "))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(exercise.category.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(exercise.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(exercise.category.color.opacity(0.15))
                    .cornerRadius(8)
                Text(exercise.equipment)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(12)
        .background(Color.gymCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
