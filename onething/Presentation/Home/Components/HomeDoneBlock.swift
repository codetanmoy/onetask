import SwiftUI
import SwiftData

struct HomeDoneBlock: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    let entry: DayEntry?
    let isCompleted: Bool
    let isRunning: Bool
    let elapsedSeconds: Int
    let options: HomeOptions
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var showCelebration = false

    var body: some View {
        let hasTask = entry?.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

        VStack(alignment: .leading, spacing: 14) {
            if isCompleted, let completedAt = entry?.completedAt {
                completedView(completedAt: completedAt)
            } else if !hasTask {
                emptyStateView
            } else if isRunning {
                runningStateView
            } else {
                pausedStateView
            }
        }
    }
    
    // MARK: - Completed State
    private func completedView(completedAt: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            OneThingSectionHeader(title: "Completed")

            // Celebration card
            HStack(alignment: .center, spacing: 14) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: showCelebration)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Well done! 🎉")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.green.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.green.opacity(0.2), lineWidth: 1)
                    )
            )
            .onAppear {
                if !reduceMotion {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCelebration = true
                    }
                }
            }

            // Start another task button
            premiumButton(
                title: "Start Another Task",
                icon: "plus.circle.fill",
                gradient: [.accentColor, .accentColor.opacity(0.8)]
            ) {
                runAnimated {
                    viewModel.handle(.startAnotherTask, context: modelContext, options: options)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            OneThingSectionHeader(title: "Next")
            
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title3)
                Text("Add your one thing above to begin.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - Running State
    private var runningStateView: some View {
        VStack(alignment: .leading, spacing: 14) {
            OneThingSectionHeader(title: "Next")
            
            Text("Pause when you need a break, or complete when the work is done.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // Pause button
                premiumButton(
                    title: "Pause",
                    icon: "pause.fill",
                    gradient: [.orange, .orange.opacity(0.8)],
                    isFullWidth: true
                ) {
                    runAnimated {
                        viewModel.handle(.startStopTapped, context: modelContext, options: options)
                    }
                }

                // Complete button
                premiumButton(
                    title: "Complete",
                    icon: "checkmark.circle.fill",
                    gradient: [.green, .mint],
                    isFullWidth: true
                ) {
                    runAnimated {
                        viewModel.handle(.markDoneTapped, context: modelContext, options: options)
                    }
                }
            }
        }
    }
    
    // MARK: - Paused State
    private var pausedStateView: some View {
        VStack(alignment: .leading, spacing: 14) {
            OneThingSectionHeader(title: "Next")

            Text(elapsedSeconds == 0 
                 ? "Start the timer whenever you're ready, it will keep counting."
                 : "Resume the timer when you're ready.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            premiumButton(
                title: elapsedSeconds == 0 ? "Start Timer" : "Resume Timer",
                icon: "play.fill",
                gradient: [.accentColor, .accentColor.opacity(0.8)]
            ) {
                runAnimated {
                    viewModel.handle(.startStopTapped, context: modelContext, options: options)
                }
            }
        }
    }
    
    // MARK: - Premium Button
    private func premiumButton(
        title: String,
        icon: String,
        gradient: [Color],
        isFullWidth: Bool = true
    ) -> some View {
        Button {
            // Action handled by caller
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: gradient.first?.opacity(0.4) ?? .clear, radius: 8, x: 0, y: 4)
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
    
    // Actual action buttons
    private func premiumButton(
        title: String,
        icon: String,
        gradient: [Color],
        isFullWidth: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: 48)
                .foregroundStyle(.white)
        }
        .buttonStyle(PremiumButtonStyle(gradient: gradient))
    }

    private func runAnimated(_ body: () -> Void) {
        if reduceMotion {
            body()
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                body()
            }
        }
    }
}

// MARK: - Premium Button Style
struct PremiumButtonStyle: ButtonStyle {
    let gradient: [Color]
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: gradient.first?.opacity(configuration.isPressed ? 0.2 : 0.4) ?? .clear,
                        radius: configuration.isPressed ? 4 : 8,
                        x: 0,
                        y: configuration.isPressed ? 2 : 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
