import SwiftUI
import SwiftData

struct HomeTimelineContent: View {
    @Environment(\.modelContext) private var modelContext

    let now: Date
    let dayToken: Date
    @ObservedObject var viewModel: HomeViewModel
    let options: HomeOptions

    var body: some View {
        content
            .task(id: dayToken) {
                viewModel.handle(.onAppear, context: modelContext, options: options)
            }
    }

    private var content: some View {
        let entry = viewModel.entry
        let elapsed = entry?.totalElapsedSeconds(now: now) ?? 0
        let isRunning = entry?.isRunning ?? false
        let isCompleted = entry?.isCompleted ?? false

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                // Streak display with loss aversion psychology
                if viewModel.state.streakDays > 0 {
                    if isCompleted && viewModel.state.previousStreakDays < viewModel.state.streakDays {
                        // Show celebration when streak increments
                        StreakCelebration(
                            oldStreak: viewModel.state.previousStreakDays,
                            newStreak: viewModel.state.streakDays
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        StreakBadge(
                            streakDays: viewModel.state.streakDays,
                            isAtRisk: viewModel.state.streakAtRisk
                        )
                    }
                }

                OneThingCard {
                    HomeTaskBlock(entry: entry, isCompleted: isCompleted, options: options, viewModel: viewModel)
                }

                OneThingCard {
                    HomeTimerBlock(entry: entry, elapsedSeconds: elapsed, isRunning: isRunning, isCompleted: isCompleted, options: options, viewModel: viewModel)
                }

                OneThingCard {
                    HomeDoneBlock(
                        entry: entry,
                        isCompleted: isCompleted,
                        isRunning: isRunning,
                        elapsedSeconds: elapsed,
                        options: options,
                        viewModel: viewModel
                    )
                }

                if !viewModel.recentEntries.isEmpty {
                    OneThingCard {
                        HomeRecentBlock(entries: viewModel.recentEntries)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .oneThingScreenBackground()
    }
}
