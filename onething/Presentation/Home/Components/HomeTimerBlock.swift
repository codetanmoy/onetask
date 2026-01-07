import SwiftUI
import SwiftData

struct HomeTimerBlock: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    let entry: DayEntry?
    let elapsedSeconds: Int
    let isRunning: Bool
    let isCompleted: Bool
    let options: HomeOptions
    @ObservedObject var viewModel: HomeViewModel
    
    
    // Timer progress based on 1 hour as full circle - resets every hour
    private var timerProgress: Double {
        let targetSeconds = 3600.0 // 1 hour full circle
        let secondsInCurrentHour = Double(elapsedSeconds % 3600)
        return secondsInCurrentHour / targetSeconds
    }
    
    private var completedHours: Int {
        return elapsedSeconds / 3600
    }


    var body: some View {
        let hasTask = entry?.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let canReset = !isCompleted && (elapsedSeconds > 0 || isRunning)

        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack(alignment: .center) {
                OneThingSectionHeader(title: "Timer")
                Spacer(minLength: 0)
                
                if isRunning {
                    // Minimal pulsing running indicator
                    HStack(spacing: 6) {
                        PulsingIndicator(color: .primary, size: 8)
                        Text("Running")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.secondarySystemBackground))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                if canReset {
                    Button {
                        runAnimated {
                            viewModel.state.showResetConfirmation = true
                        }
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(.secondary)
                    .accessibilityLabel("Reset timer")
                }
            }

            // Premium timer display with circular progress
            ZStack {
                // Circular progress ring
                CircularProgressRing(
                    progress: timerProgress,
                    isRunning: isRunning,
                    lineWidth: 10
                )
                .frame(width: 180, height: 180)
                
                // Timer text centered
                VStack(spacing: 4) {
                    // Hour badge for multi-hour sessions
                    if completedHours > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("×\(completedHours + 1)")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.tertiarySystemBackground))
                        )
                    }
                    
                    Text(DurationFormatter.timer(elapsedSeconds))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(reduceMotion ? .identity : .numericText())
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: elapsedSeconds)
                    
                    if isRunning {
                        Text("Focus time")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                }
                .accessibilityLabel(timerAccessibilityLabel(task: entry?.taskText, elapsedSeconds: elapsedSeconds))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            if !hasTask {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                    Text("Add a task to start the timer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
            }
        }
    }

    private func timerAccessibilityLabel(task: String?, elapsedSeconds: Int) -> Text {
        let trimmedTask = (task ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let taskPart = trimmedTask.isEmpty ? "Timer" : trimmedTask
        return Text("\(taskPart), \(DurationFormatter.timer(elapsedSeconds)) elapsed")
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
