import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tag(0)
                .toolbar(.hidden, for: .tabBar)
            WorkoutView()
                .tag(1)
                .toolbar(.hidden, for: .tabBar)
            NutritionView()
                .tag(2)
                .toolbar(.hidden, for: .tabBar)
            SleepView()
                .tag(3)
                .toolbar(.hidden, for: .tabBar)
            FriendsView()
                .tag(4)
                .toolbar(.hidden, for: .tabBar)
            CalendarView()
                .tag(5)
                .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab.rawValue
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab.rawValue ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab.rawValue ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab.rawValue ? tab.color : Color.white.opacity(0.4))
                            .scaleEffect(selectedTab == tab.rawValue ? 1.15 : 1.0)
                        Text(tab.title)
                            .font(.system(size: 9, weight: selectedTab == tab.rawValue ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab.rawValue ? tab.color : Color.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            Color.gymCard.opacity(0.97)
                .overlay(alignment: .top) {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.white.opacity(0.12))
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

enum TabItem: Int, CaseIterable, Identifiable {
    case dashboard = 0, workout, nutrition, sleep, friends, calendar

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .workout:   return "Workout"
        case .nutrition: return "Nutrition"
        case .sleep:     return "Sleep"
        case .friends:   return "Friends"
        case .calendar:  return "Calendar"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar"
        case .workout:   return "dumbbell"
        case .nutrition: return "fork.knife"
        case .sleep:     return "moon"
        case .friends:   return "person.2"
        case .calendar:  return "calendar"
        }
    }

    var selectedIcon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .workout:   return "dumbbell.fill"
        case .nutrition: return "fork.knife"
        case .sleep:     return "moon.fill"
        case .friends:   return "person.2.fill"
        case .calendar:  return "calendar"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return .gymPrimary
        case .workout:   return .gymOrange
        case .nutrition: return .gymGreen
        case .sleep:     return .gymPurple
        case .friends:   return Color(red: 0.0, green: 0.9, blue: 0.7) // Teal
        case .calendar:  return .gymYellow
        }
    }
}
