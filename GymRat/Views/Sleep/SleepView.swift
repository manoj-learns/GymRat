import SwiftUI
import SwiftData
import Charts

struct SleepView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepEntry.date, order: .reverse) private var sleepEntries: [SleepEntry]

    @State private var showAddSleep = false

    private let calendar = Calendar.current

    var lastNight: SleepEntry? { sleepEntries.first }

    var last7Days: [(day: String, hours: Double, quality: Int)] {
        (-6...0).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let entry = sleepEntries.first { calendar.isDate($0.date, inSameDayAs: date) }
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE"
            return (fmt.string(from: date), entry?.durationHours ?? 0, entry?.quality ?? 0)
        }
    }

    var avgSleep: Double {
        let valid = last7Days.filter { $0.hours > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.map { $0.hours }.reduce(0, +) / Double(valid.count)
    }

    var avgQuality: Double {
        let valid = last7Days.filter { $0.quality > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.map { Double($0.quality) }.reduce(0, +) / Double(valid.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        sleepScoreCard
                        weeklyStatsRow
                        sleepDurationChart
                        sleepQualityChart
                        recentEntriesList
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSleep = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.gymPurple)
                    }
                }
            }
            .sheet(isPresented: $showAddSleep) {
                AddSleepView()
            }
        }
    }

    // MARK: - Sleep Score Card
    private var sleepScoreCard: some View {
        HStack(spacing: 0) {
            // Score
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gymPurple.opacity(0.15), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: sleepScoreProgress)
                        .stroke(
                            LinearGradient.gymPurpleGrad,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text("\(sleepScore)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text("/ 100")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Text("Sleep Score")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.leading, 20)

            Spacer()

            // Details
            VStack(alignment: .leading, spacing: 12) {
                if let last = lastNight {
                    SleepDetailRow(icon: "moon.fill", label: "Duration",
                                   value: String(format: "%.1fh", last.durationHours), color: .gymPurple)
                    SleepDetailRow(icon: "bed.double.fill", label: "Bedtime",
                                   value: last.bedtime.formatted(date: .omitted, time: .shortened), color: .gymPrimary)
                    SleepDetailRow(icon: "alarm.fill", label: "Wake Time",
                                   value: last.wakeTime.formatted(date: .omitted, time: .shortened), color: .gymOrange)
                    SleepDetailRow(icon: "star.fill", label: "Quality",
                                   value: last.qualityLabel, color: last.qualityColor)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No sleep logged")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Tap + to log last night's sleep")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 20)
        .gymCard()
    }

    private var sleepScore: Int {
        guard let last = lastNight else { return 0 }
        let durationScore = min(last.durationHours / 8.0, 1.0) * 60
        let qualityScore = Double(last.quality) / 5.0 * 40
        return Int(durationScore + qualityScore)
    }

    private var sleepScoreProgress: Double { Double(sleepScore) / 100.0 }

    // MARK: - Weekly Stats
    private var weeklyStatsRow: some View {
        HStack(spacing: 0) {
            WeeklyStatItem(value: String(format: "%.1fh", avgSleep), label: "Avg Sleep", color: .gymPurple)
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            WeeklyStatItem(value: String(format: "%.1f", avgQuality), label: "Avg Quality", color: .gymYellow)
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            WeeklyStatItem(
                value: "\(last7Days.filter { $0.hours > 0 }.count)",
                label: "Days Logged",
                color: .gymGreen
            )
        }
        .padding()
        .gymCard()
    }

    // MARK: - Duration Chart
    private var sleepDurationChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Sleep Duration", icon: "moon.fill", color: .gymPurple)
            Chart {
                ForEach(last7Days, id: \.day) { entry in
                    BarMark(
                        x: .value("Day", entry.day),
                        y: .value("Hours", entry.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red:0.7,green:0.3,blue:1.0), Color(red:0.4,green:0.1,blue:0.8)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Goal", 8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(.gymGreen.opacity(0.6))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("8h")
                            .font(.system(size: 10))
                            .foregroundStyle(.gymGreen.opacity(0.7))
                    }
            }
            .frame(height: 150)
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

    // MARK: - Quality Chart
    private var sleepQualityChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Sleep Quality", icon: "star.fill", color: .gymYellow)
            Chart {
                ForEach(last7Days, id: \.day) { entry in
                    LineMark(
                        x: .value("Day", entry.day),
                        y: .value("Quality", entry.quality)
                    )
                    .foregroundStyle(Color.gymYellow)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    if entry.quality > 0 {
                        PointMark(
                            x: .value("Day", entry.day),
                            y: .value("Quality", entry.quality)
                        )
                        .foregroundStyle(qualityColor(entry.quality))
                        .symbolSize(60)
                    }
                }
            }
            .frame(height: 130)
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3, 4, 5]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.white.opacity(0.1))
                    if let q = value.as(Int.self) {
                        AxisValueLabel(qualityLabel(q))
                            .foregroundStyle(.white.opacity(0.4))
                            .font(.system(size: 9))
                    }
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

    private func qualityLabel(_ q: Int) -> String {
        switch q {
        case 0: return ""
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excel"
        default: return ""
        }
    }

    private func qualityColor(_ q: Int) -> Color {
        switch q {
        case 1, 2: return .gymRed
        case 3: return .gymYellow
        case 4, 5: return .gymGreen
        default: return .gymPrimary
        }
    }

    // MARK: - Recent Entries
    private var recentEntriesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            if sleepEntries.isEmpty {
                EmptyStateRow(text: "No sleep entries yet. Tap + to start tracking!")
            } else {
                ForEach(sleepEntries.prefix(10)) { entry in
                    SleepEntryCard(entry: entry)
                        .swipeActions {
                            Button(role: .destructive) {
                                modelContext.delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Sleep Detail Row
struct SleepDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Sleep Entry Card
struct SleepEntryCard: View {
    let entry: SleepEntry

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gymPurple.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.gymPurple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(entry.bedtime.formatted(date: .omitted, time: .shortened))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                    Text(entry.wakeTime.formatted(date: .omitted, time: .shortened))
                }
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1fh", entry.durationHours))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.gymPurple)
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= entry.quality ? "star.fill" : "star")
                            .font(.system(size: 9))
                            .foregroundStyle(star <= entry.quality ? Color.gymYellow : Color.white.opacity(0.2))
                    }
                }
            }
        }
        .padding(14)
        .gymCard()
    }
}

// MARK: - Add Sleep View
struct AddSleepView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var bedtime: Date = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
    @State private var wakeTime: Date = Date()
    @State private var quality: Int = 3
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Duration preview
                        let duration = max(0, wakeTime.timeIntervalSince(bedtime)) / 3600
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Text(String(format: "%.1f hrs", duration))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(.gymPurple)
                                Text("Sleep Duration")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)

                        FormCard {
                            HStack {
                                Image(systemName: "bed.double.fill")
                                    .foregroundStyle(.gymPurple)
                                    .frame(width: 28)
                                DatePicker("Bedtime", selection: $bedtime, displayedComponents: [.date, .hourAndMinute])
                                    .foregroundStyle(.white)
                                    .tint(.gymPurple)
                            }
                            Divider().background(Color.white.opacity(0.08))
                            HStack {
                                Image(systemName: "alarm.fill")
                                    .foregroundStyle(.gymOrange)
                                    .frame(width: 28)
                                DatePicker("Wake Time", selection: $wakeTime, displayedComponents: [.date, .hourAndMinute])
                                    .foregroundStyle(.white)
                                    .tint(.gymOrange)
                            }
                        }

                        // Quality picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sleep Quality")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))

                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { q in
                                    Button {
                                        quality = q
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: q <= quality ? "star.fill" : "star")
                                                .font(.system(size: 24))
                                                .foregroundStyle(q <= quality ? Color.gymYellow : Color.white.opacity(0.2))
                                            Text(qualityLabel(q))
                                                .font(.system(size: 9, weight: q == quality ? .bold : .regular))
                                                .foregroundStyle(q == quality ? .gymYellow : .white.opacity(0.3))
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .gymCard()

                        // Notes
                        FormCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes (optional)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                                TextField("How did you sleep?", text: $notes, axis: .vertical)
                                    .foregroundStyle(.white)
                                    .tint(.gymPurple)
                                    .lineLimit(3, reservesSpace: true)
                            }
                        }

                        Button { saveSleep() } label: {
                            Text("Log Sleep")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient.gymPurpleGrad)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gymBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.gymPurple)
                }
            }
        }
    }

    private func qualityLabel(_ q: Int) -> String {
        switch q {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excel"
        default: return ""
        }
    }

    private func saveSleep() {
        let entry = SleepEntry(
            date: wakeTime,
            bedtime: bedtime,
            wakeTime: wakeTime,
            quality: quality,
            notes: notes
        )
        modelContext.insert(entry)
        dismiss()
    }
}
