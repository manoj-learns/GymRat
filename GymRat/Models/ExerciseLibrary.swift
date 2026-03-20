import Foundation
import SwiftUI

struct Exercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: String
    let instructions: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Exercise, rhs: Exercise) -> Bool { lhs.id == rhs.id }
}

enum ExerciseCategory: String, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"

    var color: Color {
        switch self {
        case .chest: return .gymOrange
        case .back: return .gymPrimary
        case .shoulders: return .gymPurple
        case .biceps: return .gymGreen
        case .triceps: return Color(red: 0.0, green: 0.9, blue: 0.7)
        case .legs: return .gymRed
        case .core: return .gymYellow
        case .cardio: return Color(red: 1.0, green: 0.5, blue: 0.8)
        case .fullBody: return Color(red: 0.5, green: 0.8, blue: 1.0)
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.strengthtraining.traditional"
        case .shoulders: return "figure.boxing"
        case .biceps: return "dumbbell.fill"
        case .triceps: return "dumbbell"
        case .legs: return "figure.walk"
        case .core: return "figure.core.training"
        case .cardio: return "figure.run"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}

struct ExerciseLibrary {
    static let all: [Exercise] = chest + back + shoulders + biceps + triceps + legs + core + cardio + fullBody

    static let chest: [Exercise] = [
        Exercise(name: "Bench Press", category: .chest,
                 primaryMuscles: ["Pectoralis Major"], secondaryMuscles: ["Triceps", "Anterior Deltoid"],
                 equipment: "Barbell", instructions: "Lie flat on bench, grip bar slightly wider than shoulder width, lower to chest and press up."),
        Exercise(name: "Incline Bench Press", category: .chest,
                 primaryMuscles: ["Upper Pectoralis"], secondaryMuscles: ["Triceps", "Anterior Deltoid"],
                 equipment: "Barbell", instructions: "Set bench to 30-45°, press bar from upper chest upward."),
        Exercise(name: "Decline Bench Press", category: .chest,
                 primaryMuscles: ["Lower Pectoralis"], secondaryMuscles: ["Triceps"],
                 equipment: "Barbell", instructions: "Set bench to -15°, press bar from lower chest upward."),
        Exercise(name: "Dumbbell Fly", category: .chest,
                 primaryMuscles: ["Pectoralis Major"], secondaryMuscles: ["Biceps"],
                 equipment: "Dumbbell", instructions: "Lie flat, extend arms out to sides with slight bend, bring together above chest."),
        Exercise(name: "Cable Crossover", category: .chest,
                 primaryMuscles: ["Pectoralis Major"], secondaryMuscles: ["Anterior Deltoid"],
                 equipment: "Cable Machine", instructions: "Stand between cables, pull handles forward and cross at chest level."),
        Exercise(name: "Push-Up", category: .chest,
                 primaryMuscles: ["Pectoralis Major"], secondaryMuscles: ["Triceps", "Core"],
                 equipment: "Bodyweight", instructions: "Start in plank, lower chest to floor, push back up."),
        Exercise(name: "Chest Dip", category: .chest,
                 primaryMuscles: ["Pectoralis Major"], secondaryMuscles: ["Triceps"],
                 equipment: "Parallel Bars", instructions: "Lean forward on dip bars, lower until chest is level with hands."),
        Exercise(name: "Pec Deck", category: .chest,
                 primaryMuscles: ["Pectoralis Major"], secondaryMuscles: [],
                 equipment: "Machine", instructions: "Sit at machine, bring padded arms together in front of chest."),
    ]

    static let back: [Exercise] = [
        Exercise(name: "Deadlift", category: .back,
                 primaryMuscles: ["Erector Spinae", "Gluteus Maximus"], secondaryMuscles: ["Hamstrings", "Trapezius"],
                 equipment: "Barbell", instructions: "Stand with bar over feet, hip-width stance, hinge at hips and lift."),
        Exercise(name: "Pull-Up", category: .back,
                 primaryMuscles: ["Latissimus Dorsi"], secondaryMuscles: ["Biceps", "Rear Deltoid"],
                 equipment: "Pull-Up Bar", instructions: "Hang from bar with overhand grip, pull chest to bar."),
        Exercise(name: "Chin-Up", category: .back,
                 primaryMuscles: ["Latissimus Dorsi", "Biceps"], secondaryMuscles: ["Rear Deltoid"],
                 equipment: "Pull-Up Bar", instructions: "Hang from bar with underhand grip, pull chin above bar."),
        Exercise(name: "Bent-Over Barbell Row", category: .back,
                 primaryMuscles: ["Latissimus Dorsi", "Rhomboids"], secondaryMuscles: ["Biceps", "Posterior Deltoid"],
                 equipment: "Barbell", instructions: "Hinge at hips, pull bar to lower chest, squeeze shoulder blades."),
        Exercise(name: "Lat Pulldown", category: .back,
                 primaryMuscles: ["Latissimus Dorsi"], secondaryMuscles: ["Biceps", "Teres Major"],
                 equipment: "Cable Machine", instructions: "Sit at machine, pull bar down to upper chest, lean slightly back."),
        Exercise(name: "Seated Cable Row", category: .back,
                 primaryMuscles: ["Rhomboids", "Latissimus Dorsi"], secondaryMuscles: ["Biceps"],
                 equipment: "Cable Machine", instructions: "Sit at rowing machine, pull handle to abdomen, keep chest up."),
        Exercise(name: "T-Bar Row", category: .back,
                 primaryMuscles: ["Latissimus Dorsi", "Rhomboids"], secondaryMuscles: ["Biceps"],
                 equipment: "T-Bar Machine", instructions: "Straddle the bar, hinge forward, pull weight to chest."),
        Exercise(name: "Face Pull", category: .back,
                 primaryMuscles: ["Rear Deltoid", "Trapezius"], secondaryMuscles: ["External Rotators"],
                 equipment: "Cable Machine", instructions: "Pull rope attachment to face level, keeping elbows high."),
        Exercise(name: "Hyperextension", category: .back,
                 primaryMuscles: ["Erector Spinae"], secondaryMuscles: ["Gluteus Maximus"],
                 equipment: "GHD Machine", instructions: "Hinge at hips over the pad, lower and raise torso."),
    ]

    static let shoulders: [Exercise] = [
        Exercise(name: "Overhead Press", category: .shoulders,
                 primaryMuscles: ["Anterior Deltoid", "Medial Deltoid"], secondaryMuscles: ["Triceps", "Upper Trapezius"],
                 equipment: "Barbell", instructions: "Press barbell from shoulders overhead, lock arms out fully."),
        Exercise(name: "Arnold Press", category: .shoulders,
                 primaryMuscles: ["All Deltoid Heads"], secondaryMuscles: ["Triceps"],
                 equipment: "Dumbbell", instructions: "Start with palms facing you, rotate and press dumbbells overhead."),
        Exercise(name: "Lateral Raise", category: .shoulders,
                 primaryMuscles: ["Medial Deltoid"], secondaryMuscles: ["Supraspinatus"],
                 equipment: "Dumbbell", instructions: "Raise arms out to sides to shoulder height, slight forward lean."),
        Exercise(name: "Front Raise", category: .shoulders,
                 primaryMuscles: ["Anterior Deltoid"], secondaryMuscles: [],
                 equipment: "Dumbbell", instructions: "Lift dumbbells straight in front to shoulder height."),
        Exercise(name: "Rear Delt Fly", category: .shoulders,
                 primaryMuscles: ["Posterior Deltoid"], secondaryMuscles: ["Rhomboids", "Trapezius"],
                 equipment: "Dumbbell", instructions: "Bend over, raise arms to sides squeezing rear delts."),
        Exercise(name: "Upright Row", category: .shoulders,
                 primaryMuscles: ["Medial Deltoid", "Trapezius"], secondaryMuscles: ["Biceps"],
                 equipment: "Barbell", instructions: "Pull bar up along body to chin height, elbows high."),
        Exercise(name: "Shrug", category: .shoulders,
                 primaryMuscles: ["Upper Trapezius"], secondaryMuscles: [],
                 equipment: "Barbell", instructions: "Lift shoulders toward ears, hold briefly, lower slowly."),
    ]

    static let biceps: [Exercise] = [
        Exercise(name: "Barbell Curl", category: .biceps,
                 primaryMuscles: ["Biceps Brachii"], secondaryMuscles: ["Brachialis"],
                 equipment: "Barbell", instructions: "Stand with barbell, curl to shoulders keeping elbows fixed."),
        Exercise(name: "Dumbbell Curl", category: .biceps,
                 primaryMuscles: ["Biceps Brachii"], secondaryMuscles: ["Brachialis"],
                 equipment: "Dumbbell", instructions: "Alternate curling dumbbells to shoulders."),
        Exercise(name: "Hammer Curl", category: .biceps,
                 primaryMuscles: ["Brachialis", "Brachioradialis"], secondaryMuscles: ["Biceps Brachii"],
                 equipment: "Dumbbell", instructions: "Curl with neutral grip (thumbs up) to shoulders."),
        Exercise(name: "Preacher Curl", category: .biceps,
                 primaryMuscles: ["Biceps Brachii"], secondaryMuscles: [],
                 equipment: "Preacher Bench", instructions: "Rest arms on angled pad, curl barbell to chin."),
        Exercise(name: "Concentration Curl", category: .biceps,
                 primaryMuscles: ["Biceps Brachii"], secondaryMuscles: [],
                 equipment: "Dumbbell", instructions: "Seated, rest elbow on inner thigh, curl dumbbell to shoulder."),
        Exercise(name: "Cable Curl", category: .biceps,
                 primaryMuscles: ["Biceps Brachii"], secondaryMuscles: [],
                 equipment: "Cable Machine", instructions: "Stand at low cable, curl bar handle to shoulders."),
        Exercise(name: "Incline Dumbbell Curl", category: .biceps,
                 primaryMuscles: ["Biceps Brachii (Long Head)"], secondaryMuscles: [],
                 equipment: "Dumbbell", instructions: "Lie back on incline bench, curl dumbbells with full range."),
    ]

    static let triceps: [Exercise] = [
        Exercise(name: "Tricep Dip", category: .triceps,
                 primaryMuscles: ["Triceps Brachii"], secondaryMuscles: ["Pectoralis", "Anterior Deltoid"],
                 equipment: "Parallel Bars", instructions: "Lower body between bars until elbows at 90°, press back up."),
        Exercise(name: "Skull Crusher", category: .triceps,
                 primaryMuscles: ["Triceps Brachii"], secondaryMuscles: [],
                 equipment: "Barbell", instructions: "Lie flat, lower bar to forehead, extend arms fully."),
        Exercise(name: "Tricep Pushdown", category: .triceps,
                 primaryMuscles: ["Triceps Brachii"], secondaryMuscles: [],
                 equipment: "Cable Machine", instructions: "Stand at high cable, push bar down keeping elbows fixed."),
        Exercise(name: "Overhead Tricep Extension", category: .triceps,
                 primaryMuscles: ["Triceps Brachii (Long Head)"], secondaryMuscles: [],
                 equipment: "Dumbbell", instructions: "Hold dumbbell overhead with both hands, lower behind head."),
        Exercise(name: "Close-Grip Bench Press", category: .triceps,
                 primaryMuscles: ["Triceps Brachii"], secondaryMuscles: ["Pectoralis"],
                 equipment: "Barbell", instructions: "Use narrow grip on bench press, elbows stay close to body."),
        Exercise(name: "Diamond Push-Up", category: .triceps,
                 primaryMuscles: ["Triceps Brachii"], secondaryMuscles: ["Pectoralis"],
                 equipment: "Bodyweight", instructions: "Push-up with hands close together forming a diamond shape."),
    ]

    static let legs: [Exercise] = [
        Exercise(name: "Squat", category: .legs,
                 primaryMuscles: ["Quadriceps", "Gluteus Maximus"], secondaryMuscles: ["Hamstrings", "Core"],
                 equipment: "Barbell", instructions: "Bar on upper back, squat until thighs parallel to floor."),
        Exercise(name: "Romanian Deadlift", category: .legs,
                 primaryMuscles: ["Hamstrings", "Gluteus Maximus"], secondaryMuscles: ["Erector Spinae"],
                 equipment: "Barbell", instructions: "Hinge at hips, lower bar along legs while keeping back flat."),
        Exercise(name: "Leg Press", category: .legs,
                 primaryMuscles: ["Quadriceps", "Gluteus Maximus"], secondaryMuscles: ["Hamstrings"],
                 equipment: "Machine", instructions: "Push platform away, lower until knees at 90°."),
        Exercise(name: "Leg Extension", category: .legs,
                 primaryMuscles: ["Quadriceps"], secondaryMuscles: [],
                 equipment: "Machine", instructions: "Sit at machine, extend legs fully, lower with control."),
        Exercise(name: "Leg Curl", category: .legs,
                 primaryMuscles: ["Hamstrings"], secondaryMuscles: [],
                 equipment: "Machine", instructions: "Lie on machine, curl legs toward glutes."),
        Exercise(name: "Calf Raise", category: .legs,
                 primaryMuscles: ["Gastrocnemius", "Soleus"], secondaryMuscles: [],
                 equipment: "Machine", instructions: "Stand on edge, raise heels as high as possible."),
        Exercise(name: "Hack Squat", category: .legs,
                 primaryMuscles: ["Quadriceps"], secondaryMuscles: ["Gluteus Maximus"],
                 equipment: "Machine", instructions: "On hack squat machine, lower until thighs are parallel."),
        Exercise(name: "Lunge", category: .legs,
                 primaryMuscles: ["Quadriceps", "Gluteus Maximus"], secondaryMuscles: ["Hamstrings"],
                 equipment: "Bodyweight", instructions: "Step forward, lower back knee toward floor, return."),
        Exercise(name: "Bulgarian Split Squat", category: .legs,
                 primaryMuscles: ["Quadriceps", "Gluteus Maximus"], secondaryMuscles: ["Hamstrings"],
                 equipment: "Dumbbell", instructions: "Rear foot elevated, lower front knee to ground and drive up."),
        Exercise(name: "Hip Thrust", category: .legs,
                 primaryMuscles: ["Gluteus Maximus"], secondaryMuscles: ["Hamstrings"],
                 equipment: "Barbell", instructions: "Shoulders on bench, drive hips up with bar on hips."),
        Exercise(name: "Sumo Squat", category: .legs,
                 primaryMuscles: ["Inner Thigh", "Gluteus Maximus"], secondaryMuscles: ["Quadriceps"],
                 equipment: "Dumbbell", instructions: "Wide stance, toes out, squat holding single dumbbell."),
    ]

    static let core: [Exercise] = [
        Exercise(name: "Plank", category: .core,
                 primaryMuscles: ["Transversus Abdominis", "Rectus Abdominis"], secondaryMuscles: ["Obliques"],
                 equipment: "Bodyweight", instructions: "Hold push-up position on forearms for time."),
        Exercise(name: "Crunch", category: .core,
                 primaryMuscles: ["Rectus Abdominis"], secondaryMuscles: [],
                 equipment: "Bodyweight", instructions: "Lie on back, lift shoulders off floor contracting abs."),
        Exercise(name: "Russian Twist", category: .core,
                 primaryMuscles: ["Obliques"], secondaryMuscles: ["Rectus Abdominis"],
                 equipment: "Bodyweight", instructions: "Seated V-sit, rotate torso side to side."),
        Exercise(name: "Leg Raise", category: .core,
                 primaryMuscles: ["Lower Rectus Abdominis"], secondaryMuscles: ["Hip Flexors"],
                 equipment: "Bodyweight", instructions: "Lie flat, raise straight legs to vertical, lower slowly."),
        Exercise(name: "Ab Wheel Rollout", category: .core,
                 primaryMuscles: ["Rectus Abdominis", "Transversus Abdominis"], secondaryMuscles: ["Latissimus Dorsi"],
                 equipment: "Ab Wheel", instructions: "On knees, roll wheel forward extending body, pull back."),
        Exercise(name: "Cable Crunch", category: .core,
                 primaryMuscles: ["Rectus Abdominis"], secondaryMuscles: [],
                 equipment: "Cable Machine", instructions: "Kneel at cable, crunch down crunching abs against resistance."),
        Exercise(name: "Side Plank", category: .core,
                 primaryMuscles: ["Obliques"], secondaryMuscles: ["Transversus Abdominis"],
                 equipment: "Bodyweight", instructions: "Side-lying, support on one forearm, hips raised for time."),
        Exercise(name: "Mountain Climber", category: .core,
                 primaryMuscles: ["Core", "Hip Flexors"], secondaryMuscles: ["Chest", "Shoulders"],
                 equipment: "Bodyweight", instructions: "In push-up position, alternate driving knees to chest rapidly."),
        Exercise(name: "Dead Bug", category: .core,
                 primaryMuscles: ["Transversus Abdominis"], secondaryMuscles: ["Rectus Abdominis"],
                 equipment: "Bodyweight", instructions: "On back, extend opposite arm and leg while keeping lower back flat."),
    ]

    static let cardio: [Exercise] = [
        Exercise(name: "Running", category: .cardio,
                 primaryMuscles: ["Quadriceps", "Hamstrings", "Calves"], secondaryMuscles: ["Glutes", "Core"],
                 equipment: "None", instructions: "Maintain steady pace, land midfoot, arms at 90°."),
        Exercise(name: "Cycling", category: .cardio,
                 primaryMuscles: ["Quadriceps", "Hamstrings"], secondaryMuscles: ["Glutes", "Calves"],
                 equipment: "Bicycle/Stationary Bike", instructions: "Steady cadence, adjust resistance for intensity."),
        Exercise(name: "Rowing Machine", category: .cardio,
                 primaryMuscles: ["Back", "Legs", "Arms"], secondaryMuscles: ["Core"],
                 equipment: "Rowing Machine", instructions: "Drive with legs, hinge back, pull handles to chest."),
        Exercise(name: "Jump Rope", category: .cardio,
                 primaryMuscles: ["Calves"], secondaryMuscles: ["Shoulders", "Core"],
                 equipment: "Jump Rope", instructions: "Small jumps, rotate wrists, land lightly on balls of feet."),
        Exercise(name: "Elliptical", category: .cardio,
                 primaryMuscles: ["Quadriceps", "Hamstrings"], secondaryMuscles: ["Glutes", "Arms"],
                 equipment: "Elliptical Machine", instructions: "Push and pull handles while stepping in elliptical motion."),
        Exercise(name: "Stair Climber", category: .cardio,
                 primaryMuscles: ["Glutes", "Quadriceps"], secondaryMuscles: ["Calves"],
                 equipment: "Stair Climber", instructions: "Maintain upright posture, step at steady rhythm."),
        Exercise(name: "Swimming", category: .cardio,
                 primaryMuscles: ["Full Body"], secondaryMuscles: [],
                 equipment: "Pool", instructions: "Full stroke with flutter kicks, breathe bilaterally."),
        Exercise(name: "Battle Ropes", category: .cardio,
                 primaryMuscles: ["Shoulders", "Arms"], secondaryMuscles: ["Core", "Legs"],
                 equipment: "Battle Ropes", instructions: "Alternating or simultaneous wave patterns."),
    ]

    static let fullBody: [Exercise] = [
        Exercise(name: "Burpee", category: .fullBody,
                 primaryMuscles: ["Full Body"], secondaryMuscles: [],
                 equipment: "Bodyweight", instructions: "Squat down, jump feet back to push-up, jump feet forward, jump up."),
        Exercise(name: "Kettlebell Swing", category: .fullBody,
                 primaryMuscles: ["Hamstrings", "Glutes"], secondaryMuscles: ["Core", "Shoulders"],
                 equipment: "Kettlebell", instructions: "Hinge at hips, swing kettlebell to shoulder height using hip drive."),
        Exercise(name: "Clean and Press", category: .fullBody,
                 primaryMuscles: ["Full Body"], secondaryMuscles: [],
                 equipment: "Barbell", instructions: "Clean barbell to shoulders, press overhead."),
        Exercise(name: "Thruster", category: .fullBody,
                 primaryMuscles: ["Quadriceps", "Shoulders"], secondaryMuscles: ["Triceps", "Core"],
                 equipment: "Barbell", instructions: "Front squat combined with overhead press in one movement."),
        Exercise(name: "Turkish Get-Up", category: .fullBody,
                 primaryMuscles: ["Core", "Shoulders"], secondaryMuscles: ["Hips", "Legs"],
                 equipment: "Kettlebell", instructions: "Rise from lying to standing while keeping weight overhead."),
    ]
}
