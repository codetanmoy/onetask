import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
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
        }.navigationTitle("One Task")
    }
}

#Preview {
    RootView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
