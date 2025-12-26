import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage(UserPreferences.onboardingCompleteKey) private var onboardingComplete: Bool = false

    var body: some View {
        ZStack {
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
            .navigationTitle("One Task")

            if !onboardingComplete {
                OnboardingView(isComplete: $onboardingComplete)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
