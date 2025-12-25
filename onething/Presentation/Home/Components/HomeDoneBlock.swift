import SwiftUI
import SwiftData

struct HomeDoneBlock: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let entry: DayEntry?
    let isCompleted: Bool
    let isRunning: Bool
    let elapsedSeconds: Int
    let options: HomeOptions
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        let hasTask = entry?.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

        VStack(alignment: .leading, spacing: 10) {
            if isCompleted, let completedAt = entry?.completedAt {
                OneThingSectionHeader(title: "Completed")

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Done")
                            .font(.headline)
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }

                Button {
                    runAnimated {
                        viewModel.handle(.startAnotherTask, context: modelContext, options: options)
                    }
                } label: {
                    Label("Start Another Task", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            } else if !hasTask {
                OneThingSectionHeader(title: "Next")
                Text("Add your one thing above to begin.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if isRunning {
                OneThingSectionHeader(title: "Next")
                Text("Stop the timer when you’re done working.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    runAnimated {
                        viewModel.handle(.startStopTapped, context: modelContext, options: options)
                    }
                } label: {
                    Label("Stop Timer", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            } else {
                OneThingSectionHeader(title: "Next")

                if elapsedSeconds == 0 {
                    Text("Start the timer or mark done if you finished without timing.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            runAnimated {
                                viewModel.handle(.startStopTapped, context: modelContext, options: options)
                            }
                        } label: {
                            Label("Start Timer", systemImage: "play.fill")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)

                        Button {
                            runAnimated {
                                viewModel.handle(.markDoneTapped, context: modelContext, options: options)
                            }
                        } label: {
                            Text("Mark Done")
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                    }
                } else {
                    Text("Mark done when you’re finished.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        runAnimated {
                            viewModel.handle(.markDoneTapped, context: modelContext, options: options)
                        }
                    } label: {
                        Label("Mark Done", systemImage: "checkmark")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)

                    Button {
                        runAnimated {
                            viewModel.handle(.startStopTapped, context: modelContext, options: options)
                        }
                    } label: {
                        Text("Start Again")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
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
