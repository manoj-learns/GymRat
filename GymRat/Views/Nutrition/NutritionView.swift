import SwiftUI
import SwiftData
import Charts

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var allFoods: [FoodEntry]

    @State private var showAddFood = false
    @State private var showCamera = false
    @State private var selectedMeal: MealType = .breakfast
    @State private var foodToEdit: FoodEntry?

    private let calorieGoal: Double = 2200
    private let calendar = Calendar.current

    var todayFoods: [FoodEntry] {
        allFoods.filter { calendar.isDateInToday($0.date) }
    }

    var todayCalories: Double { todayFoods.reduce(0) { $0 + $1.calories } }
    var todayProtein: Double  { todayFoods.reduce(0) { $0 + $1.protein } }
    var todayCarbs: Double    { todayFoods.reduce(0) { $0 + $1.carbs } }
    var todayFat: Double      { todayFoods.reduce(0) { $0 + $1.fat } }

    func mealFoods(_ meal: MealType) -> [FoodEntry] {
        todayFoods.filter { $0.mealType == meal.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        calorieProgressCard
                        macroStatsRow
                        mealsSection
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Menu {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Scan Food with AI", systemImage: "camera.fill")
                            }
                            Button {
                                showAddFood = true
                            } label: {
                                Label("Add Manually", systemImage: "square.and.pencil")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.gymGreenGrad)
                                    .frame(width: 60, height: 60)
                                    .shadow(color: .gymGreen.opacity(0.5), radius: 10, y: 4)
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddFood) {
                ManualFoodEntryView()
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraFoodView()
            }
            .sheet(item: $foodToEdit) { food in
                EditFoodEntryView(food: food)
            }
        }
    }

    // MARK: - Calorie Progress Ring
    private var calorieProgressCard: some View {
        HStack(spacing: 24) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color.gymOrange.opacity(0.15), lineWidth: 14)
                    .frame(width: 130, height: 130)
                Circle()
                    .trim(from: 0, to: min(todayCalories / calorieGoal, 1.0))
                    .stroke(
                        LinearGradient.gymOrangeGrad,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(todayCalories))")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Text("kcal")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                CalorieStatRow(label: "Goal", value: "\(Int(calorieGoal)) kcal", color: .white.opacity(0.5))
                CalorieStatRow(
                    label: "Remaining",
                    value: "\(max(0, Int(calorieGoal - todayCalories))) kcal",
                    color: todayCalories > calorieGoal ? .gymRed : .gymGreen
                )
                CalorieStatRow(label: "Logged", value: "\(todayFoods.count) items", color: .gymPrimary)
            }
            Spacer()
        }
        .padding(20)
        .gymCard()
    }

    // MARK: - Macro Stats Row
    private var macroStatsRow: some View {
        HStack(spacing: 12) {
            MacroStatCard(label: "Protein", value: todayProtein, unit: "g",
                          goal: 150, color: .gymPrimary)
            MacroStatCard(label: "Carbs",   value: todayCarbs,   unit: "g",
                          goal: 250, color: .gymOrange)
            MacroStatCard(label: "Fat",     value: todayFat,     unit: "g",
                          goal: 65,  color: .gymPurple)
        }
    }

    // MARK: - Meals Section
    private var mealsSection: some View {
        VStack(spacing: 14) {
            ForEach(MealType.allCases, id: \.self) { meal in
                MealSection(
                    meal: meal,
                    foods: mealFoods(meal),
                    onDelete: deleteFood,
                    onEdit: { foodToEdit = $0 }
                )
            }
        }
    }

    private func deleteFood(_ food: FoodEntry) {
        modelContext.delete(food)
    }
}

// MARK: - Calorie Stat Row
struct CalorieStatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Macro Stat Card
struct MacroStatCard: View {
    let label: String
    let value: Double
    let unit: String
    let goal: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Text("\(Int(value))\(unit)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
            ProgressView(value: min(value / goal, 1.0))
                .tint(color)
                .scaleEffect(x: 1, y: 1.5)
            Text("/ \(Int(goal))\(unit)")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .gymCard()
    }
}

// MARK: - Meal Section
struct MealSection: View {
    let meal: MealType
    let foods: [FoodEntry]
    let onDelete: (FoodEntry) -> Void
    var onEdit: ((FoodEntry) -> Void)? = nil

    var totalCalories: Double { foods.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: meal.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(meal.color)
                    Text(meal.rawValue)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                if totalCalories > 0 {
                    Text("\(Int(totalCalories)) kcal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(meal.color)
                }
            }
            .padding(14)

            if foods.isEmpty {
                HStack {
                    Text("Nothing logged yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            } else {
                HStack {
                    Spacer()
                    Label("Swipe to edit or delete", systemImage: "hand.point.left")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 2)
                ForEach(foods) { food in
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.horizontal, 14)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(food.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                            HStack(spacing: 8) {
                                Text("P: \(Int(food.protein))g")
                                Text("C: \(Int(food.carbs))g")
                                Text("F: \(Int(food.fat))g")
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        Text("\(Int(food.calories))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text("kcal")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { onDelete(food) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button { onEdit?(food) } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.gymGreen)
                    }
                }
            }
        }
        .background(Color.gymCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(meal.color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Manual Food Entry
struct ManualFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var mealType: MealType = .breakfast

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormCard {
                            GymTextField(label: "Food Name", text: $name, placeholder: "e.g., Grilled Chicken")
                        }

                        FormCard {
                            GymTextField(label: "Calories", text: $calories, placeholder: "kcal", keyboardType: .decimalPad)
                            Divider().background(Color.white.opacity(0.08))
                            GymTextField(label: "Protein (g)", text: $protein, placeholder: "0", keyboardType: .decimalPad)
                            Divider().background(Color.white.opacity(0.08))
                            GymTextField(label: "Carbs (g)", text: $carbs, placeholder: "0", keyboardType: .decimalPad)
                            Divider().background(Color.white.opacity(0.08))
                            GymTextField(label: "Fat (g)", text: $fat, placeholder: "0", keyboardType: .decimalPad)
                        }

                        FormCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Meal Type")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                                HStack(spacing: 8) {
                                    ForEach(MealType.allCases, id: \.self) { meal in
                                        Button {
                                            mealType = meal
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: meal.icon)
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(mealType == meal ? .white : meal.color.opacity(0.7))
                                                Text(meal.rawValue)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(mealType == meal ? .white : .white.opacity(0.5))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(mealType == meal ? meal.color : Color.gymCard2)
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                        }

                        Button { saveFood() } label: {
                            Text("Add Food")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient.gymGreenGrad)
                                .cornerRadius(14)
                        }
                        .disabled(name.isEmpty || calories.isEmpty)
                        .opacity(name.isEmpty || calories.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Add Food")
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

    private func saveFood() {
        let food = FoodEntry(
            name: name,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            mealType: mealType.rawValue
        )
        modelContext.insert(food)
        dismiss()
    }
}

// MARK: - Helper Views
struct FormCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(14)
            .gymCard()
    }
}

struct GymTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 110, alignment: .leading)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .tint(.gymGreen)
        }
        .padding(.vertical, 2)
    }
}
