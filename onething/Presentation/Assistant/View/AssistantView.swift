import SwiftUI
import SwiftData

struct AssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var assistant = OneThingAssistantManager()
    @FocusState private var isInputFocused: Bool

    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true
    @AppStorage(UserPreferences.retentionDaysKey) private var retentionDays: Int = Constants.defaultRetentionDays
    @AppStorage(UserPreferences.hapticsEnabledKey) private var hapticsEnabled: Bool = true

    @State private var input: String = ""

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .center,spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .center, spacing: 10) {
                        ForEach(assistant.messages) { message in
                            messageBubble(message)
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
                    .padding(.bottom, 8)
                    
                }
               
                .onTapGesture {
                    isInputFocused = false
                }
                .onChange(of: assistant.messages) { _, _ in
                    guard let last = assistant.messages.last else { return }
                    withAnimation(.easeInOut(duration: 0.22)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: assistant.isGenerating) { _, newValue in
                    guard newValue else { return }
                    withAnimation(.easeInOut(duration: 0.22)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }

                inputBar
            }
            .oneThingScreenBackground()
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .task { assistant.seedIfNeeded() }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Message…")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }

                TextField("", text: $input, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($isInputFocused)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                Task {
                    assistant.seedIfNeeded()
                    let ctx = makeContext()
                    await assistant.send(userText: input, context: ctx, actions: actions)
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
    private func messageBubble(_ message: OneThingAssistantManager.Message) -> some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 0) }
            Group {
                if message.role == .assistant && message.kind == .menu {
                    AssistantMenuBubble()
                } else {
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
            stopTimer: {
                try AssistantActionService.stopTimerIfRunning(
                    context: modelContext,
                    dailyResetEnabled: dailyResetEnabled
                )
                HapticsService.lightImpact(enabled: hapticsEnabled)
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
