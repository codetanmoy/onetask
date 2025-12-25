import SwiftUI
import SwiftData

struct HomeTimerBlock: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let entry: DayEntry?
    let elapsedSeconds: Int
    let isRunning: Bool
    let isCompleted: Bool
    let options: HomeOptions
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        let hasTask = entry?.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let canReset = !isCompleted && (elapsedSeconds > 0 || isRunning)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                OneThingSectionHeader(title: "Timer")
                Spacer(minLength: 0)
                if isRunning {
                    Text("Running")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.12))
                        .clipShape(Capsule())
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

            Text(DurationFormatter.timer(elapsedSeconds))
                .font(.system(size: 55, weight: .bold, design: .rounded))
                .monospacedDigit()
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: elapsedSeconds)
                .accessibilityLabel(timerAccessibilityLabel(task: entry?.taskText, elapsedSeconds: elapsedSeconds))

            if !hasTask {
                Text("Add a task to start the timer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
