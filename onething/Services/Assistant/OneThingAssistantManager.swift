import Foundation
import Combine
import SwiftUI
import FoundationModels

@MainActor
final class OneThingAssistantManager: ObservableObject {
    struct Message: Identifiable, Equatable {
        enum Kind: Equatable {
            case text
            case menu
            case running(taskText: String, previousElapsedSeconds: Int, startedAt: Date?)
        }
        enum Role { case user, assistant }
        let id = UUID()
        let role: Role
        let kind: Kind
        let text: String
    }

    struct Reply: Equatable {
        var kind: Message.Kind
        var text: String
    }

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var flow: FlowState = .menu

    struct Actions {
        var setTaskText: (_ text: String) async throws -> Void
        var startTimer: () async throws -> Void
        var pauseTimer: () async throws -> Void
        var completeTask: () async throws -> Void
        var daySummary: (_ day: Date) async throws -> String
    }

    enum FlowState: Equatable {
        case menu
        case createTaskAwaitName
        case createTaskAwaitStartTimer(taskText: String)
        case summaryAskDate
    }

    func reset() {
        messages.removeAll()
        flow = .menu
    }

    func seedIfNeeded(context: AssistantContext? = nil) {
        guard messages.isEmpty else { return }
        if let context, context.today.isRunning {
            showRunningStatus(context: context)
            return
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            messages.append(.init(role: .assistant, kind: .menu, text: ""))
        }
    }

    func send(userText: String, context: AssistantContext?, actions: Actions) async {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            messages.append(.init(role: .user, kind: .text, text: trimmed))
        }
        isGenerating = true
        defer { isGenerating = false }

        let reply = await generateReply(userText: trimmed, context: context, actions: actions)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            messages.append(.init(role: .assistant, kind: reply.kind, text: reply.text))
        }
    }

    func rewriteTask(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return "Write it as one concrete action. Example: “Draft the first paragraph of the email.”" }

        var out = trimmed
        out = out.replacingOccurrences(of: "\n", with: " ")
        out = out.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Heuristic: drop obvious multi-task separators to push toward one line.
        out = out.components(separatedBy: CharacterSet(charactersIn: ";,&")).first ?? out
        out = out.trimmingCharacters(in: .whitespacesAndNewlines)
        out = String(out.prefix(Constants.maxTaskLength))

        if out.isEmpty { return "Pick one concrete action. Example: “Outline the first section.”" }
        return out
    }

    private func normalizedTaskText(from text: String) -> String? {
        let candidate = rewriteTask(stripTaskPrefixes(from: text))
        guard candidate.contains("Example:") == false else { return nil }
        return candidate
    }

    private func stripTaskPrefixes(from text: String) -> String {
        let lower = text.lowercased()
        let prefixes = [
            "today:",
            "task:",
            "my one thing is",
            "one thing is",
            "my task is",
            "today -",
            "today —",
        ]
        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let start = text.index(text.startIndex, offsetBy: prefix.count)
                return String(text[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return text
    }

    private func generateReply(userText: String, context: AssistantContext?, actions: Actions) async -> Reply {
        // If the user asks for planning or lists, refuse gently via structured clarify intent.
        if violatesScope(userText) {
            let guardrailCommand = IntentParser.Command(
                intent: .clarify,
                confidence: 0.6,
                taskText: "",
                question: "I can’t help with schedules; what single task would you like?",
                reason: "Scope guardrail triggered"
            )
            let json = intentCommandJSON(guardrailCommand)
            return Reply(kind: .text, text: json)
        }

        if let guided = await handleGuidedFlow(userText: userText, context: context, actions: actions) {
            return Reply(kind: guided.kind, text: OneThingAssistantGuardrails.enforce(guided.text))
        }

        let command = await parseIntentCommand(userText: userText, context: context)
        let json = intentCommandJSON(command)
        return Reply(kind: .text, text: json)
    }

    private func handleGuidedFlow(userText: String, context: AssistantContext?, actions: Actions) async -> Reply? {
        let lower = userText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch flow {
        case .menu:
            if lower == "1" || lower.contains("create") {
                flow = .createTaskAwaitName
                return Reply(kind: .text, text: """
                What’s the task name?
                Keep it as one clear action.
                """)
            }
            if lower == "2" || lower.contains("details") {
                return Reply(kind: .text, text: detailsReply(context: context))
            }
            if lower == "3" || lower.contains("summary") {
                flow = .summaryAskDate
                return Reply(kind: .text, text: """
                Which date?
                Send “today” or YYYY-MM-DD.
                """)
            }
            if lower == "today" {
                let today = Calendar.current.startOfDay(for: .now)
                do {
                    let summary = try await actions.daySummary(today)
                    return Reply(kind: .text, text: summary)
                } catch {
                    return Reply(kind: .text, text: """
                    I couldn’t load today’s summary right now.
                    Try again in a moment or pick another date.
                    """)
                }
            }
            if await wantsToStartTimer(userText: lower, context: context) {
                guard let taskText = context?.today.taskText.trimmingCharacters(in: .whitespacesAndNewlines), taskText.isEmpty == false else {
                    return Reply(kind: .text, text: """
                    Please set your task before starting the timer.
                    """)
                }
                do {
                    try await actions.startTimer()
                    flow = .menu
                    return Reply(kind: .text, text: """
                    Timer started.
                    Task set: \(taskText)
                    Timer is running now. Would you like to stop it?
                    """)
                } catch {
                    flow = .menu
                    return Reply(kind: .text, text: """
                    Task is set: \(taskText)
                    I couldn’t start the timer here.
                    """)
                }
            }
            return Reply(kind: .menu, text: "")

        case .createTaskAwaitName:
            let rewritten = rewriteTask(userText)
            do {
                try await actions.setTaskText(rewritten)
                flow = .createTaskAwaitStartTimer(taskText: rewritten)
                return Reply(kind: .text, text: """
                Task set: \(rewritten)
                Start the timer now?
                """)
            } catch {
                flow = .menu
                return Reply(kind: .text, text: """
                I couldn’t set that task.
                Try a shorter one-line task.
                """)
            }

        case let .createTaskAwaitStartTimer(taskText):
            if isAffirmative(lower) {
                do {
                    try await actions.startTimer()
                    flow = .menu
                    return Reply(kind: .text, text: """
                    Timer started.
                    Task set: \(taskText)
                    Timer is running now. Would you like to stop it?
                    """)
                } catch {
                    flow = .menu
                    return Reply(kind: .text, text: """
                    Task is set: \(taskText)
                    I couldn’t start the timer here.
                    """)
                }
            }
            flow = .menu
            return Reply(kind: .text, text: """
            Okay.
            When you begin, start the timer in Home.
            """)

        case .summaryAskDate:
            let day = parseDay(lower)
            guard let day else {
                return Reply(kind: .text, text: """
                I didn’t get that date.
                Send “today” or YYYY-MM-DD.
                """)
            }
            do {
                let summary = try await actions.daySummary(day)
                flow = .menu
                return Reply(kind: .text, text: summary)
            } catch {
                flow = .menu
                return Reply(kind: .text, text: """
                I couldn’t load that day.
                Try another date.
                """)
            }
        }
    }

    private func wantsToStartTimer(userText: String, context: AssistantContext?) async -> Bool {
        guard let context else { return false }
        let task = context.today.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard task.isEmpty == false, context.today.isRunning == false else { return false }

        let lower = userText.lowercased()
        let directPhrases = [
            "start now",
            "start timer",
            "start it",
            "start work",
            "start the timer",
            "start doing",
            "let's start",
            "go ahead",
            "i'm ready",
            "start today"
        ]
        if directPhrases.contains(where: lower.contains) { return true }
        if isAffirmative(lower) { return true }

        guard case .available = FoundationModelManager.availability else { return false }
        let instruction = """
        Help classify whether the user is asking to start today’s timer.
        Answer “Yes” if they want to start it now, otherwise answer “No”.
        Keep the answer short.
        """
        let prompt = """
        App context: the timer is not running and a task is set for today.
        User said: “\(userText)”
        Should you start today’s timer?
        """
        do {
            let response = try await FoundationModelManager.generate(system: instruction, user: prompt)
            return response.lowercased().contains("yes")
        } catch {
            return false
        }
    }

    private func detailsReply(context: AssistantContext?) -> String {
        guard let context else {
            return """
            I don’t have access to today’s status right now.
            You can check it on Home.
            """
        }

        let task = context.today.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        let taskLine = task.isEmpty ? "Task: (not set)" : "Task: \(task)"
        let statusLine = context.today.completed ? "Status: done" : (context.today.isRunning ? "Status: running" : "Status: stopped")
        let timeLine = "Time: \(DurationFormatter.timer(context.today.elapsedSeconds))"
        let nextLine: String = {
            if context.today.completed { return "Next: start another task in Home." }
            if task.isEmpty { return "Next: choose 1 to create a task." }
            if context.today.isRunning { return "Next: stop timer when you pause." }
            return "Next: start timer when you begin."
        }()

        return [taskLine, statusLine, timeLine, nextLine].joined(separator: "\n")
    }

    private func isAffirmative(_ lower: String) -> Bool {
        let tokens = [
            "y", "yes", "yep", "sure", "ok", "okay", "go", "start", "begin",
            "let's start", "i'm ready", "ready", "sounds good"
        ]
        return tokens.contains(where: lower.contains)
    }

    private func parseDay(_ lower: String) -> Date? {
        if lower == "today" {
            return Calendar.current.startOfDay(for: .now)
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: lower) else { return nil }
        return Calendar.current.startOfDay(for: date)
    }

    private func violatesScope(_ text: String) -> Bool {
        let lower = text.lowercased()
        let forbiddenHints = [
            "schedule", "plan my day", "daily plan", "routine", "habit", "streak",
            "block apps", "app blocker", "pomodoro schedule", "calendar", "multi task",
        ]
        return forbiddenHints.contains { lower.contains($0) }
    }

    private func parseIntentCommand(userText: String, context: AssistantContext?) async -> IntentParser.Command {
        let parserContext = intentParserContext(from: context)
        guard case .available = FoundationModelManager.availability else {
            return fallbackIntentCommand(userText: userText, context: parserContext)
        }

        let prompt = IntentParser.prompt(context: parserContext, userText: userText)
        do {
            let raw = try await FoundationModelManager.generate(system: IntentParser.instructions, user: prompt)
            if let parsed = IntentParser.decodeResponse(raw) {
                return parsed
            }
        } catch {
            // fall through to fallback
        }

        return fallbackIntentCommand(userText: userText, context: parserContext)
    }

    private func intentParserContext(from context: AssistantContext?) -> IntentParser.Context {
        let hasTask = context?.today.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let isRunning = context?.today.isRunning ?? false
        let isCompleted = context?.today.completed ?? false
        return IntentParser.Context(
            hasTask: hasTask,
            isRunning: isRunning,
            isCompleted: isCompleted,
            pendingAction: pendingIntentAction
        )
    }

    private var pendingIntentAction: IntentParser.Context.PendingAction {
        switch flow {
        case .createTaskAwaitStartTimer:
            return .startTimer
        default:
            return .none
        }
    }

    private func intentCommandJSON(_ command: IntentParser.Command) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(command), let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func fallbackIntentCommand(userText: String, context: IntentParser.Context) -> IntentParser.Command {
        let lower = userText.lowercased()
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)

        if context.pendingAction == .startTimer, isAffirmative(lower) {
            return IntentParser.Command(
                intent: .start_timer,
                confidence: 0.82,
                taskText: "",
                question: "",
                reason: "Confirmed pending start"
            )
        }

        let startPatterns = ["start timer", "start now", "start it", "go ahead", "begin", "let's start", "start work"]
        if startPatterns.contains(where: lower.contains) {
            return IntentParser.Command(
                intent: .start_timer,
                confidence: 0.85,
                taskText: "",
                question: "",
                reason: "Direct start request"
            )
        }

        let stopPatterns = ["stop timer", "pause timer", "pause", "stop it", "halt"]
        if stopPatterns.contains(where: lower.contains) {
            return IntentParser.Command(
                intent: .stop_timer,
                confidence: 0.8,
                taskText: "",
                question: "",
                reason: "Requested timer stop"
            )
        }

        if lower.contains("reset") {
            return IntentParser.Command(
                intent: .reset_timer,
                confidence: 0.75,
                taskText: "",
                question: "",
                reason: "Asked to reset timer"
            )
        }

        let donePatterns = ["mark done", "i'm done", "i am done", "done for today", "finished"]
        if donePatterns.contains(where: lower.contains) {
            return IntentParser.Command(
                intent: .mark_done,
                confidence: 0.78,
                taskText: "",
                question: "",
                reason: "User wants to finish task"
            )
        }

        if lower.contains("undo") {
            return IntentParser.Command(
                intent: .undo_done,
                confidence: 0.7,
                taskText: "",
                question: "",
                reason: "Undo request detected"
            )
        }

        if lower.contains("history") {
            return IntentParser.Command(
                intent: .show_history,
                confidence: 0.72,
                taskText: "",
                question: "",
                reason: "Asked for history"
            )
        }

        if lower.contains("setting") || lower.contains("pref") {
            return IntentParser.Command(
                intent: .open_settings,
                confidence: 0.7,
                taskText: "",
                question: "",
                reason: "Settings request detected"
            )
        }

        if lower.contains("help") || lower.contains("how do") || lower.contains("how does") {
            return IntentParser.Command(
                intent: .help,
                confidence: 0.68,
                taskText: "",
                question: "",
                reason: "Help requested"
            )
        }

        if lower.contains("change it to") || lower.contains("edit task") {
            if let taskText = normalizedTaskText(from: userText) {
                return IntentParser.Command(
                    intent: .edit_task,
                    confidence: 0.7,
                    taskText: taskText,
                    question: "",
                    reason: "User asked to update task"
                )
            }
        }

        let hintsForSetTask = ["my one thing is", "one thing is", "today:", "task is", "my task"]
        if hintsForSetTask.contains(where: lower.contains) {
            if let taskText = normalizedTaskText(from: userText) {
                return IntentParser.Command(
                    intent: .set_task,
                    confidence: 0.7,
                    taskText: taskText,
                    question: "",
                    reason: "Outlined a new task"
                )
            }
        }

        if context.hasTask == false, let taskText = normalizedTaskText(from: userText) {
            return IntentParser.Command(
                intent: .set_task,
                confidence: 0.65,
                taskText: taskText,
                question: "",
                reason: "Assumed new task"
            )
        }

        if trimmed.isEmpty {
            return IntentParser.Command(
                intent: .clarify,
                confidence: 0.5,
                taskText: "",
                question: "What action should I take?",
                reason: "Empty input"
            )
        }

        return IntentParser.Command(
            intent: .clarify,
            confidence: 0.55,
            taskText: "",
            question: "Do you want to start the timer or mark done?",
            reason: "Need clarification"
        )
    }

    func showRunningStatus(context: AssistantContext?) {
        guard let context, context.today.isRunning else { return }
        if case .running = messages.last?.kind { return }
        let task = context.today.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageText = runningStatusText(context: context)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            messages.append(.init(
                role: .assistant,
                kind: .running(
                    taskText: task,
                    previousElapsedSeconds: context.today.previousElapsedSeconds,
                    startedAt: context.today.startedAt
                ),
                text: messageText
            ))
        }
    }

    func clearRunningStatus() {
        if case .running = messages.last?.kind {
            _ = withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                messages.removeLast()
            }
        }
    }

    func showMenuIfNeeded() {
        if case .menu = messages.last?.kind { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            messages.append(.init(role: .assistant, kind: .menu, text: ""))
        }
    }

    private func runningStatusText(context: AssistantContext) -> String {
        let task = context.today.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        let taskLine = task.isEmpty ? "Your task is running." : "Task \"\(task)\" is running."
        let timerLine = "Timer: \(DurationFormatter.timer(context.today.elapsedSeconds))"
        return """
        \(taskLine)
        \(timerLine)
        Would you like to stop it?
        """
    }

    private struct IntentParser {
        struct Context: Codable {
            let hasTask: Bool
            let isRunning: Bool
            let isCompleted: Bool
            let pendingAction: PendingAction

            enum CodingKeys: String, CodingKey {
                case hasTask = "has_task"
                case isRunning = "is_running"
                case isCompleted = "is_completed"
                case pendingAction = "pending_action"
            }

            enum PendingAction: String, Codable {
                case startTimer = "start_timer"
                case resetTimer = "reset_timer"
                case markDone = "mark_done"
                case none = ""
            }
        }

        struct Command: Codable {
            let intent: Intent
            let confidence: Double
            let taskText: String
            let question: String
            let reason: String

            enum Intent: String, Codable {
                case start_timer
                case stop_timer
                case reset_timer
                case mark_done
                case undo_done
                case set_task
                case edit_task
                case show_history
                case open_settings
                case help
                case clarify
                case noop
            }

            enum CodingKeys: String, CodingKey {
                case intent
                case confidence
                case taskText = "task_text"
                case question
                case reason
            }
        }

        static let instructions: String = """
        You are an intent parser for the OneThing app.
        Your only job is to turn the user’s message into a single JSON command that the app can execute.
        Output must be valid JSON without surrounding markdown or extra text.
        Choose exactly one intent from: start_timer, stop_timer, reset_timer, mark_done, undo_done, set_task, edit_task, show_history, open_settings, help, clarify, noop.
        Provide confidence between 0.0 and 1.0, include only one task_text string, include question only when intent is clarify, and write a short reason (max 12 words).
        Use only the provided context object (has_task, is_running, is_completed, pending_action) to decide how to interpret agreement keywords.
        pending_action can be start_timer, reset_timer, mark_done, or an empty string when no confirmation is pending.
        If the intent is ambiguous, set intent to clarify and ask one short question.
        Do not invent features outside the allowed intents.
        """

        static func prompt(context: Context, userText: String) -> String {
            let contextJSON = self.contextJSON(context)
            return """
            Context:
            \(contextJSON)

            User message:
            \(userText)
            """
        }

        static func contextJSON(_ context: Context) -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard let data = try? encoder.encode(context), let json = String(data: data, encoding: .utf8) else {
                return "{}"
            }
            return json
        }

        static func decodeResponse(_ raw: String) -> Command? {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let candidate: String
            if let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") {
                candidate = String(trimmed[start ... end])
            } else {
                candidate = trimmed
            }
            guard let data = candidate.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(Command.self, from: data)
        }
    }

}
