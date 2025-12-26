import SwiftUI
import SwiftData
import Combine

struct AssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assistant = OneThingAssistantManager()
    @FocusState private var isInputFocused: Bool

    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true
    @AppStorage(UserPreferences.retentionDaysKey) private var retentionDays: Int = Constants.defaultRetentionDays
    @AppStorage(UserPreferences.hapticsEnabledKey) private var hapticsEnabled: Bool = true

    @State private var input: String = ""

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    ScrollView {
                    LazyVStack(alignment: .center, spacing: 10) {
                        ForEach(assistant.messages) { message in
                            messageBubble(message, proxy: proxy)
                            .id(message.id)
                            .transition(.opacity.combined(with: .move(edge: message.role == .user ? .trailing : .leading)))
                        }
                            if assistant.isGenerating {
                                typingBubble
                                    .id("typing")
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 148)
                    }
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onReceive(assistant.$messages) { _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: assistant.isGenerating) { _, newValue in
                        if newValue {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        } else {
                            scrollToBottom(proxy)
                        }
                    }
                    .onAppear {
                        scrollToBottom(proxy)
                    }

                    inputBar(proxy: proxy)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .oneThingScreenBackground()
                .navigationTitle("Assistant")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                .task { assistant.seedIfNeeded(context: makeContext()) }

                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.callout.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(Color(.systemBackground).opacity(0.85))
                        .clipShape(Capsule())
                }
                .padding(.top, 18)
                .padding(.trailing, 18)
            }
        }
    }

    private func inputBar(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $input, axis: .vertical)
                .lineLimit(1...3)
                .focused($isInputFocused)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                Task {
                    let ctx = makeContext()
                    await assistant.send(userText: input, context: ctx, actions: actions)
                    assistant.showRunningStatus(context: makeContext())
                    scrollToBottom(proxy)
                    input = ""
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
            }
            .buttonStyle(.plain)
            .disabled(assistant.isGenerating || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity((assistant.isGenerating || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.45 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial)
        .overlay {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(.separator).opacity(0.25))
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: OneThingAssistantManager.Message, proxy: ScrollViewProxy) -> some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 0) }
            Group {
                switch message.kind {
                case .menu:
                    AssistantMenuBubble()
                case let .running(taskText, previousElapsedSeconds, startedAt):
                    RunningAssistantBubble(
                        taskText: taskText,
                        previousElapsedSeconds: previousElapsedSeconds,
                        startedAt: startedAt
                    ) {
                        try? await actions.pauseTimer()
                        assistant.clearRunningStatus()
                        assistant.showMenuIfNeeded()
                        scrollToBottom(proxy)
                    } completeAction: {
                        try? await actions.completeTask()
                        assistant.clearRunningStatus()
                        assistant.showMenuIfNeeded()
                        scrollToBottom(proxy)
                    }
                default:
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(isUser ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(isUser ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .frame(alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer(minLength: 0) }
        }
    }

    private var typingBubble: some View {
        HStack {
            TypingIndicator()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Spacer(minLength: 0)
        }
    }

    private struct RunningAssistantBubble: View {
        let taskText: String
        let previousElapsedSeconds: Int
        let startedAt: Date?
        let pauseAction: () async -> Void
        let completeAction: () async -> Void

        @State private var now: Date = .now
        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                if taskText.isEmpty == false {
                    Text("Task: \(taskText)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                }
                Text(DurationFormatter.timer(displayedSeconds))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                Text("Timer is running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await pauseAction()
                        }
                    } label: {
                        Text("Pause")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    Button {
                        Task {
                            await completeAction()
                        }
                    } label: {
                        Text("Complete")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onReceive(timer) { value in
                now = value
            }
        }

        private var displayedSeconds: Int {
            var total = previousElapsedSeconds
            if let started = startedAt {
                let delta = Int(now.timeIntervalSince(started))
                total += max(0, delta)
            }
            return total
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = assistant.messages.last else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private struct TypingIndicator: View {
        @State private var phase: Int = 0

        var body: some View {
            HStack(spacing: 5) {
                dot(0)
                dot(1)
                dot(2)
            }
            .onAppear {
                phase = 0
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    phase = 3
                }
            }
        }

        private func dot(_ index: Int) -> some View {
            Circle()
                .fill(Color.secondary)
                .frame(width: 7, height: 7)
                .opacity(phase > index ? 1 : 0.35)
        }
    }

    private var actions: OneThingAssistantManager.Actions {
        OneThingAssistantManager.Actions(
            setTaskText: { text in
                _ = try AssistantActionService.applyTaskText(
                    text,
                    context: modelContext,
                    dailyResetEnabled: dailyResetEnabled
                )
                HapticsService.success(enabled: hapticsEnabled)
            },
            startTimer: {
                try AssistantActionService.startTimerIfPossible(
                    context: modelContext,
                    dailyResetEnabled: dailyResetEnabled
                )
                HapticsService.lightImpact(enabled: hapticsEnabled)
            },
            pauseTimer: {
                try AssistantActionService.pauseTimer(
                    context: modelContext,
                    dailyResetEnabled: dailyResetEnabled
                )
                HapticsService.lightImpact(enabled: hapticsEnabled)
            },
            completeTask: {
                try AssistantActionService.completeTask(
                    context: modelContext,
                    dailyResetEnabled: dailyResetEnabled
                )
                HapticsService.success(enabled: hapticsEnabled)
            },
            daySummary: { day in
                let entries = try DayEntryRepository.fetchEntries(forDay: day, context: modelContext)
                if entries.isEmpty {
                    return """
                    \(day.formatted(date: .abbreviated, time: .omitted))
                    No entries.
                    """
                }
                let totalSeconds = entries.reduce(0) { $0 + $1.totalElapsedSeconds() }
                let doneCount = entries.filter { $0.isCompleted }.count
                let completedTasks = entries
                    .filter { $0.isCompleted }
                    .map { $0.taskText.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                let openTasks = entries
                    .filter { !$0.isCompleted }
                    .map { $0.taskText.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                let completedLine = completedTasks.isEmpty ? "Done: —" : "Done: \(String(completedTasks.first!.prefix(40)))"
                let openLine = openTasks.isEmpty ? "Open: —" : "Open: \(String(openTasks.first!.prefix(40)))"
                return """
                \(day.formatted(date: .abbreviated, time: .omitted))
                Entries: \(entries.count) (done \(doneCount))
                Total: \(DurationFormatter.timer(totalSeconds))
                \(completedLine)
                \(openLine)
                """
            }
        )
    }

    private func makeContext() -> AssistantContext? {
        AssistantContextBuilder.make(
            context: modelContext,
            dailyResetEnabled: dailyResetEnabled,
            retentionDays: retentionDays,
            hapticsEnabled: hapticsEnabled
        )
    }
}

#Preview {
    NavigationStack {
        AssistantView()
    }
    .modelContainer(for: DayEntry.self, inMemory: true)
}
