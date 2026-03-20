import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var allFoods: [FoodEntry]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allWorkouts: [WorkoutSession]
    @Query(sort: \SleepEntry.date, order: .reverse) private var allSleeps: [SleepEntry]

    @EnvironmentObject var friendsVM: FriendsViewModel
    @StateObject private var aiService = AIService.shared
    @State private var insights: [AIInsight] = []
    @State private var isLoadingInsights = false
    @State private var showSettings = false
    @AppStorage("user_name") private var userName: String = ""

    private let calorieGoal: Double = 2200
    private let calendar = Calendar.current

    var todayFoods: [FoodEntry] {
        allFoods.filter { calendar.isDateInToday($0.date) }
    }
    var todayCalories: Double { todayFoods.reduce(0) { $0 + $1.calories } }
    var todayProtein: Double  { todayFoods.reduce(0) { $0 + $1.protein } }
    var todayCarbs: Double    { todayFoods.reduce(0) { $0 + $1.carbs } }
    var todayFat: Double      { todayFoods.reduce(0) { $0 + $1.fat } }

    var todayWorkouts: [WorkoutSession] {
        allWorkouts.filter { calendar.isDateInToday($0.date) }
    }

    var lastNightSleep: SleepEntry? {
        allSleeps.first { calendar.isDateInToday($0.date) || calendar.isDateInYesterday($0.date) }
    }

    var last7DaysCalories: [(day: String, calories: Double)] {
        (-6...0).map { offset -> (String, Double) in
            let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let foods = allFoods.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let total = foods.reduce(0) { $0 + $1.calories }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return (formatter.string(from: date), total)
        }
    }

    var last7DaysWorkoutVolume: [(day: String, volume: Double)] {
        (-6...0).map { offset -> (String, Double) in
            let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let sessions = allWorkouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let total = sessions.reduce(0) { $0 + $1.totalVolume }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return (formatter.string(from: date), total)
        }
    }

    var last7DaysSleep: [(day: String, hours: Double)] {
        (-6...0).map { offset -> (String, Double) in
            let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let sleep = allSleeps.filter { calendar.isDate($0.date, inSameDayAs: date) }.first
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return (formatter.string(from: date), sleep?.durationHours ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        todaySummaryCards
                        macroDonutChart
                        weeklyCaloriesChart
                        weeklyWorkoutChart
                        weeklySleepChart
                        insightsSection
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .task { await loadInsights() }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(friendsVM)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText + (userName.isEmpty ? "" : ", \(userName)"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Your Dashboard")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Date(), format: .dateTime.weekday(.wide))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.gymPrimary)
                    Text(Date(), format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    // MARK: - Today Summary Cards
    private var todaySummaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(
                title: "Calories",
                value: "\(Int(todayCalories))",
                subtitle: "/ \(Int(calorieGoal)) kcal",
                icon: "flame.fill",
                gradient: .gymOrangeGrad,
                progress: min(todayCalories / calorieGoal, 1.0)
            )
            SummaryCard(
                title: "Workout",
                value: "\(todayWorkouts.count)",
                subtitle: "sessions today",
                icon: "dumbbell.fill",
                gradient: .gymCyan,
                progress: min(Double(todayWorkouts.count) / 1.0, 1.0)
            )
            SummaryCard(
                title: "Sleep",
                value: String(format: "%.1fh", lastNightSleep?.durationHours ?? 0),
                subtitle: lastNightSleep?.qualityLabel ?? "Not logged",
                icon: "moon.fill",
                gradient: .gymPurpleGrad,
                progress: min((lastNightSleep?.durationHours ?? 0) / 8.0, 1.0)
            )
        }
    }

    // MARK: - Macro Donut
    private var macroDonutChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Today's Macros", icon: "chart.pie.fill", color: .gymOrange)

            if todayCalories == 0 {
                EmptyStateRow(text: "No food logged today")
            } else {
                HStack(spacing: 20) {
                    Chart {
                        SectorMark(
                            angle: .value("Protein", todayProtein * 4),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.gymPrimary)

                        SectorMark(
                            angle: .value("Carbs", todayCarbs * 4),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.gymOrange)

                        SectorMark(
                            angle: .value("Fat", todayFat * 9),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.gymPurple)
                    }
                    .frame(width: 110, height: 110)

                    VStack(alignment: .leading, spacing: 10) {
                        MacroLegendRow(label: "Protein", value: todayProtein, unit: "g", color: .gymPrimary)
                        MacroLegendRow(label: "Carbs",   value: todayCarbs,   unit: "g", color: .gymOrange)
                        MacroLegendRow(label: "Fat",     value: todayFat,     unit: "g", color: .gymPurple)
                        Divider().background(Color.white.opacity(0.1))
                        MacroLegendRow(label: "Total",   value: todayCalories, unit: "kcal", color: .white)
                    }
                    Spacer()
                }
                .padding()
                .gymCard()
            }
        }
    }

    // MARK: - Weekly Charts
    private var weeklyCaloriesChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Calories This Week", icon: "flame.fill", color: .gymOrange)
            Chart {
                ForEach(last7DaysCalories, id: \.day) { entry in
                    BarMark(
                        x: .value("Day", entry.day),
                        y: .value("Calories", entry.calories)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [.gymOrange, Color(red:1,green:0.3,blue:0)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Goal", calorieGoal))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(.white.opacity(0.4))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 10))
                }
            }
            .padding()
            .gymCard()
        }
    }

    private var weeklyWorkoutChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Workout Volume (kg)", icon: "dumbbell.fill", color: .gymPrimary)
            Chart {
                ForEach(last7DaysWorkoutVolume, id: \.day) { entry in
                    BarMark(
                        x: .value("Day", entry.day),
                        y: .value("Volume", entry.volume / 1000)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [.gymPrimary, Color(red:0,green:0.5,blue:0.9)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(6)
                }
            }
            .frame(height: 140)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 10))
                }
            }
            .padding()
            .gymCard()
        }
    }

    private var weeklySleepChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Sleep Duration (hrs)", icon: "moon.fill", color: .gymPurple)
            Chart {
                ForEach(last7DaysSleep, id: \.day) { entry in
                    BarMark(
                        x: .value("Day", entry.day),
                        y: .value("Hours", entry.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red:0.7,green:0.3,blue:1.0), Color(red:0.4,green:0.1,blue:0.8)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Recommended", 8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(.gymGreen.opacity(0.6))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("8h goal")
                            .font(.system(size: 10))
                            .foregroundStyle(.gymGreen.opacity(0.7))
                    }
            }
            .frame(height: 140)
            .chartYAxis {
                AxisMarks(values: [0, 2, 4, 6, 8]) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.system(size: 10))
                }
            }
            .padding()
            .gymCard()
        }
    }

    // MARK: - AI Insights
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "AI Insights", icon: "brain.head.profile", color: .gymPrimary)
                Spacer()
                if isLoadingInsights {
                    ProgressView()
                        .tint(.gymPrimary)
                        .scaleEffect(0.8)
                } else {
                    Button {
                        Task { await loadInsights() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundStyle(.gymPrimary)
                    }
                }
            }

            if insights.isEmpty && !isLoadingInsights {
                EmptyStateRow(text: "Log your activities to get AI insights")
            } else {
                VStack(spacing: 10) {
                    ForEach(insights) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
        }
    }

    private func loadInsights() async {
        isLoadingInsights = true
        defer { isLoadingInsights = false }

        let calories = last7DaysCalories.map { $0.calories }
        let workoutsCount = allWorkouts.filter {
            calendar.dateInterval(of: .weekOfYear, for: Date())?.contains($0.date) == true
        }.count
        let avgSleep = last7DaysSleep.filter { $0.hours > 0 }.map { $0.hours }.average
        let topExercises = Array(Set(allWorkouts.flatMap { $0.sets.map { $0.exerciseName } })).prefix(5).map { $0 }

        do {
            insights = try await AIService.shared.generateInsights(
                caloriesThisWeek: calories,
                workoutsThisWeek: workoutsCount,
                avgSleepHours: avgSleep,
                topExercises: Array(topExercises)
            )
        } catch {
            // Silently use default insights
        }
    }
}

// MARK: - Subviews
struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(gradient)
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)

            ProgressView(value: progress)
                .tint(Color.gymPrimary)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
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

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

struct MacroLegendRow: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text("\(Int(value))\(unit)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

struct InsightCard: View {
    let insight: AIInsight

    private var cardColor: Color {
        switch insight.category {
        case .workout: return .gymPrimary
        case .nutrition: return .gymOrange
        case .sleep: return .gymPurple
        case .general: return .gymGreen
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(cardColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: insight.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(cardColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text(insight.body)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.gymCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct EmptyStateRow: View {
    let text: String
    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
        .padding()
        .gymCard()
    }
}

extension [Double] {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
