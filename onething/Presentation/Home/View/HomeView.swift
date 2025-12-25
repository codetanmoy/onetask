import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = HomeViewModel()

    @AppStorage(UserPreferences.retentionDaysKey) private var retentionDays: Int = Constants.defaultRetentionDays
    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true
    @AppStorage(UserPreferences.hapticsEnabledKey) private var hapticsEnabled: Bool = true

    var body: some View {
        homeScaffold
    }

    private var homeScaffold: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HomeTimelineContent(
                now: context.date,
                dayToken: Calendar.current.startOfDay(for: context.date),
                viewModel: viewModel,
                options: options
            )
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.handle(.onAppear, context: modelContext, options: options)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            viewModel.handle(.onAppear, context: modelContext, options: options)
        }
        .alert("Reset timer?", isPresented: resetBinding) {
            Button("Reset", role: .destructive) {
                animateIfAllowed {
                    viewModel.handle(.resetConfirmed, context: modelContext, options: options)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears elapsed time for today.")
        }
        .safeAreaInset(edge: .bottom) {
            UndoToastContainer(isPresented: viewModel.state.showUndoToast) {
                animateIfAllowed {
                    viewModel.handle(.undoDone, context: modelContext, options: options)
                }
            }
        }
    }

    private var options: HomeOptions {
        HomeOptions(
            retentionDays: retentionDays,
            dailyResetEnabled: dailyResetEnabled,
            hapticsEnabled: hapticsEnabled
        )
    }

    private var resetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showResetConfirmation },
            set: { viewModel.state.showResetConfirmation = $0 }
        )
    }

    private func animateIfAllowed(_ body: () -> Void) {
        if reduceMotion {
            body()
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                body()
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: DayEntry.self, inMemory: true)
}
