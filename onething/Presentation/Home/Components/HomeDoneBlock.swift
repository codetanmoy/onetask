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

            // Minimal completion card
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .symbolEffect(.bounce, value: showCelebration)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Well done!")
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
                    .fill(Color(.secondarySystemBackground))
            )
            .onAppear {
                if !reduceMotion {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCelebration = true
                    }
                }
            }

            // Start another task button
            MinimalButton(title: "Start Another Task", icon: "plus") {
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
                Image(systemName: "arrow.up")
                    .foregroundStyle(.tertiary)
                    .font(.footnote)
                Text("Add your one thing above to begin.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Running State
    private var runningStateView: some View {
        VStack(alignment: .leading, spacing: 14) {
            OneThingSectionHeader(title: "Next")
            
            Text("Pause when you need a break, or complete when done.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // Pause button - secondary
                MinimalButton(title: "Pause", icon: "pause.fill", isPrimary: false) {
                    runAnimated {
                        viewModel.handle(.startStopTapped, context: modelContext, options: options)
                    }
                }

                // Complete button - primary
                MinimalButton(title: "Complete", icon: "checkmark") {
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
                 ? "Start the timer whenever you're ready."
                 : "Resume the timer when you're ready.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            MinimalButton(
                title: elapsedSeconds == 0 ? "Start Timer" : "Resume Timer",
                icon: "play.fill"
            ) {
                runAnimated {
                    viewModel.handle(.startStopTapped, context: modelContext, options: options)
                }
            }
        }
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

// MARK: - Minimal Button (Black & White)
struct MinimalButton: View {
    let title: String
    let icon: String
    var isPrimary: Bool = true
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(isPrimary ? (colorScheme == .dark ? .black : .white) : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isPrimary ? Color.primary : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium Button Style (kept for compatibility)
struct PremiumButtonStyle: ButtonStyle {
    let gradient: [Color]
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
