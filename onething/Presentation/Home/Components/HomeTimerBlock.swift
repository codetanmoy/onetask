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
    
    // Timer progress based on 1 hour as full circle (adjustable)
    private var timerProgress: Double {
        let targetSeconds = 3600.0 // 1 hour full circle
        return min(Double(elapsedSeconds) / targetSeconds, 1.0)
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
                    // Premium pulsing running indicator
                    HStack(spacing: 6) {
                        PulsingIndicator(color: .green, size: 8)
                        Text("Running")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .strokeBorder(.green.opacity(0.3), lineWidth: 1)
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
                    Text(DurationFormatter.timer(elapsedSeconds))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(timerTextGradient)
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
                        .foregroundStyle(.orange)
                        .font(.footnote)
                    Text("Add a task to start the timer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.orange.opacity(0.1))
                )
            }
        }
    }
    
    private var timerTextGradient: some ShapeStyle {
        if isRunning {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(Color.primary)
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
