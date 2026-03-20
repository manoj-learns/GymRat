import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workouts: [WorkoutSession]
    @Query(sort: \FoodEntry.date, order: .reverse) private var foods: [FoodEntry]
    @Query(sort: \SleepEntry.date, order: .reverse) private var sleeps: [SleepEntry]

    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date? = Date()
    @State private var showDayDetail = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    calendarHeader
                    weekdayLabels
                    calendarGrid
                    legendBar
                    Divider().background(Color.white.opacity(0.08))
                    if let date = selectedDate {
                        DayDetailView(
                            date: date,
                            workouts: dayWorkouts(date),
                            foods: dayFoods(date),
                            sleep: daySleep(date)
                        )
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Header (month nav)
    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.gymPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.gymCard)
                    .cornerRadius(12)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.gymPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.gymCard)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Weekday Labels
    private var weekdayLabels: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(daysInMonth(), id: \.self) { date in
                if let date = date {
                    DayCell(
                        date: date,
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        isToday: calendar.isDateInToday(date),
                        hasWorkout: !dayWorkouts(date).isEmpty,
                        hasFood: !dayFoods(date).isEmpty,
                        hasSleep: daySleep(date) != nil
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25)) {
                            selectedDate = date
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 52)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Legend
    private var legendBar: some View {
        HStack(spacing: 16) {
            LegendDot(color: .gymOrange, label: "Workout")
            LegendDot(color: .gymGreen, label: "Nutrition")
            LegendDot(color: .gymPurple, label: "Sleep")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    // MARK: - Data helpers
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var current = firstWeek.start

        while current < monthInterval.end {
            if calendar.isDate(current, equalTo: monthInterval.start, toGranularity: .month) ||
               (current >= monthInterval.start && current < monthInterval.end) {
                days.append(current)
            } else {
                days.append(nil)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        // Pad to complete weeks
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func dayWorkouts(_ date: Date) -> [WorkoutSession] {
        workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    private func dayFoods(_ date: Date) -> [FoodEntry] {
        foods.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    private func daySleep(_ date: Date) -> SleepEntry? {
        sleeps.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasWorkout: Bool
    let hasFood: Bool
    let hasSleep: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.gymPrimary)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .stroke(Color.gymPrimary, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .black : isToday ? .gymPrimary : .white)
            }

            // Activity dots
            HStack(spacing: 3) {
                if hasWorkout {
                    Circle().fill(Color.gymOrange).frame(width: 5, height: 5)
                }
                if hasFood {
                    Circle().fill(Color.gymGreen).frame(width: 5, height: 5)
                }
                if hasSleep {
                    Circle().fill(Color.gymPurple).frame(width: 5, height: 5)
                }
            }
            .frame(height: 7)
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.gymPrimary.opacity(0.12) : Color.clear)
        )
    }
}

// MARK: - Legend Dot
struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Day Detail View
struct DayDetailView: View {
    let date: Date
    let workouts: [WorkoutSession]
    let foods: [FoodEntry]
    let sleep: SleepEntry?

    var totalCalories: Double { foods.reduce(0) { $0 + $1.calories } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .padding(.top, 14)

                // Summary row
                HStack(spacing: 10) {
                    DaySummaryBadge(
                        icon: "dumbbell.fill", color: .gymOrange,
                        value: "\(workouts.count)", label: "Workouts"
                    )
                    DaySummaryBadge(
                        icon: "flame.fill", color: .gymGreen,
                        value: "\(Int(totalCalories))", label: "Calories"
                    )
                    DaySummaryBadge(
                        icon: "moon.fill", color: .gymPurple,
                        value: sleep != nil ? String(format: "%.1fh", sleep!.durationHours) : "—",
                        label: "Sleep"
                    )
                }
                .padding(.horizontal)

                // Workout list
                if !workouts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workouts")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.gymOrange)
                            .padding(.horizontal)
                        ForEach(workouts) { s in
                            HStack(spacing: 12) {
                                Image(systemName: "dumbbell.fill")
                                    .foregroundStyle(.gymOrange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.name.isEmpty ? "Workout" : s.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("\(s.exerciseCount) exercises · \(s.setCount) sets")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                                Spacer()
                                Text("\(Int(s.totalVolume)) kg")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.gymOrange)
                            }
                            .padding(12)
                            .gymCard()
                            .padding(.horizontal)
                        }
                    }
                }

                // Sleep detail
                if let s = sleep {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sleep")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.gymPurple)
                            .padding(.horizontal)
                        HStack(spacing: 12) {
                            Image(systemName: "moon.stars.fill")
                                .foregroundStyle(.gymPurple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.1f hours", s.durationHours))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("\(s.bedtime.formatted(date:.omitted,time:.shortened)) → \(s.wakeTime.formatted(date:.omitted,time:.shortened))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Spacer()
                            Text(s.qualityLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(s.qualityColor)
                        }
                        .padding(12)
                        .gymCard()
                        .padding(.horizontal)
                    }
                }

                if workouts.isEmpty && foods.isEmpty && sleep == nil {
                    Text("Nothing logged on this day")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .padding()
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.gymBackground)
    }
}

struct DaySummaryBadge: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
