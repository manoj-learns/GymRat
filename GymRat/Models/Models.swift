import Foundation
import SwiftData

// MARK: - Workout Session
@Model
class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var duration: TimeInterval = 0.0
    var name: String = ""
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet] = []

    init(date: Date = Date(), name: String = "Workout", notes: String = "") {
        self.id = UUID()
        self.date = date
        self.name = name
        self.notes = notes
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    var exerciseCount: Int {
        Set(sets.map { $0.exerciseName }).count
    }
    var setCount: Int { sets.count }
}

// MARK: - Workout Set
@Model
class WorkoutSet {
    var id: UUID = UUID()
    var exerciseName: String = ""
    var exerciseCategory: String = ""
    var reps: Int = 0
    var weight: Double = 0.0
    var setNumber: Int = 1
    var date: Date = Date()
    var session: WorkoutSession?

    init(exerciseName: String, exerciseCategory: String,
         reps: Int, weight: Double, setNumber: Int = 1) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.exerciseCategory = exerciseCategory
        self.reps = reps
        self.weight = weight
        self.setNumber = setNumber
        self.date = Date()
    }
}

// MARK: - Food Entry
@Model
class FoodEntry {
    var id: UUID = UUID()
    var name: String = ""
    var calories: Double = 0.0
    var protein: Double = 0.0
    var carbs: Double = 0.0
    var fat: Double = 0.0
    var date: Date = Date()
    var imagePath: String? = nil
    var mealType: String = "snack"

    init(name: String, calories: Double, protein: Double = 0,
         carbs: Double = 0, fat: Double = 0,
         date: Date = Date(), imagePath: String? = nil, mealType: String = "snack") {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
        self.imagePath = imagePath
        self.mealType = mealType
    }
}

// MARK: - Sleep Entry
@Model
class SleepEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var bedtime: Date = Date()
    var wakeTime: Date = Date()
    var quality: Int = 3
    var notes: String = ""

    init(date: Date = Date(), bedtime: Date, wakeTime: Date,
         quality: Int = 3, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.quality = quality
        self.notes = notes
    }

    var duration: TimeInterval { wakeTime.timeIntervalSince(bedtime) }
    var durationHours: Double { max(0, duration / 3600) }

    var qualityLabel: String {
        switch quality {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excellent"
        default: return "Unknown"
        }
    }

    var qualityColor: Color {
        switch quality {
        case 1, 2: return .gymRed
        case 3: return .gymYellow
        case 4, 5: return .gymGreen
        default: return .gymPrimary
        }
    }
}

import SwiftUI
// MARK: - Meal Type
enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "fork.knife"
        }
    }

    var color: Color {
        switch self {
        case .breakfast: return .gymOrange
        case .lunch: return .gymYellow
        case .dinner: return .gymPurple
        case .snack: return .gymGreen
        }
    }
}

// MARK: - Daily Summary
struct DailySummary {
    var date: Date
    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var workoutCount: Int
    var totalVolume: Double
    var sleepHours: Double
    var sleepQuality: Int
}
