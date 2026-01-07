import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage(UserPreferences.onboardingCompleteKey) private var onboardingComplete: Bool = false

    var body: some View {
        if onboardingComplete {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }

                NavigationStack {
                    HistoryView()
                }
                .tabItem {
                    Label("History", systemImage: "clock")
                }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .tint(.primary) // Black/white tab bar tint
        } else {
            OnboardingView(isComplete: $onboardingComplete)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
