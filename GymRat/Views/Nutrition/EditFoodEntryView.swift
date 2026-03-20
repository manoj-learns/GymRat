import SwiftUI

struct EditFoodEntryView: View {
    @Environment(\.dismiss) private var dismiss

    let food: FoodEntry

    @State private var name:     String
    @State private var calories: String
    @State private var protein:  String
    @State private var carbs:    String
    @State private var fat:      String
    @State private var mealType: MealType

    init(food: FoodEntry) {
        self.food = food
        _name     = State(initialValue: food.name)
        _calories = State(initialValue: "\(Int(food.calories))")
        _protein  = State(initialValue: "\(Int(food.protein))")
        _carbs    = State(initialValue: "\(Int(food.carbs))")
        _fat      = State(initialValue: "\(Int(food.fat))")
        _mealType = State(initialValue: MealType(rawValue: food.mealType) ?? .snack)
    }

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
                            GymTextField(label: "Calories",   text: $calories, placeholder: "kcal", keyboardType: .decimalPad)
                            Divider().background(Color.white.opacity(0.08))
                            GymTextField(label: "Protein (g)", text: $protein,  placeholder: "0",    keyboardType: .decimalPad)
                            Divider().background(Color.white.opacity(0.08))
                            GymTextField(label: "Carbs (g)",   text: $carbs,    placeholder: "0",    keyboardType: .decimalPad)
                            Divider().background(Color.white.opacity(0.08))
                            GymTextField(label: "Fat (g)",     text: $fat,      placeholder: "0",    keyboardType: .decimalPad)
                        }

                        FormCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Meal Type")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                                HStack(spacing: 8) {
                                    ForEach(MealType.allCases, id: \.self) { meal in
                                        Button { mealType = meal } label: {
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

                        Button { save() } label: {
                            Text("Save Changes")
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
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.gymGreen)
                }
            }
        }
    }

    private func save() {
        food.name     = name
        food.calories = Double(calories) ?? food.calories
        food.protein  = Double(protein)  ?? food.protein
        food.carbs    = Double(carbs)    ?? food.carbs
        food.fat      = Double(fat)      ?? food.fat
        food.mealType = mealType.rawValue
        dismiss()
    }
}
