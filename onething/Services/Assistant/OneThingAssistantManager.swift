import Foundation
import Combine
import SwiftUI

@MainActor
final class OneThingAssistantManager: ObservableObject {
    static let systemPrompt: String = """
    You are OneThing Assistant.
    Your role is to help users understand and use the OneThing app.
    OneThing supports one task per day, one timer, and one completion.
    Keep responses short, calm, and practical.
    Reduce choice. Convert vague tasks into one clear line.
    If a task is too big, shrink it into a smaller single outcome (not steps).
    Clarify the next action inside the app (set task, start timer, mark done).
    Refuse multi-task planning and redirect back to one thing.
    Ask at most one question.
    Do not provide medical, mental health, or therapeutic advice.
    Do not propose features outside the app’s scope (task lists, app blocking, schedules).
    Use only the app-provided context.
    If information is unavailable, say so plainly.
    Never shame the user.
    Do not store or recall personal chat content.
    """

    struct Message: Identifiable, Equatable {
        enum Kind: Equatable { case text, menu }
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
        var stopTimer: () async throws -> Void
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

    func seedIfNeeded() {
        guard messages.isEmpty else { return }
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

    private func generateReply(userText: String, context: AssistantContext?, actions: Actions) async -> Reply {
        // If the user asks for planning or lists, refuse gently.
        if violatesScope(userText) {
            return Reply(kind: .text, text: OneThingAssistantGuardrails.enforce("""
            I can’t help with schedules or multi-step plans.
            OneThing is meant for one task and one timer.
            What is the single task you want to do today?
            """))
        }

        if let guided = await handleGuidedFlow(userText: userText, context: context, actions: actions) {
            return Reply(kind: guided.kind, text: OneThingAssistantGuardrails.enforce(guided.text))
        }

        // If we have no model support, fallback to rule-based answers.
        switch FoundationModelManager.availability {
        case let .unavailable(reason):
            let fallback = ruleBasedReply(userText: userText, context: context)
            return Reply(kind: .text, text: OneThingAssistantGuardrails.enforce("""
            \(reason)
            \(fallback)
            """))
        case .available:
            break
        }

        let contextString = context.flatMap(encodeContext) ?? "{}"
        let user = """
        AppContext:
        \(contextString)

        User:
        \(userText)
        """

        do {
            let raw = try await FoundationModelManager.generate(system: Self.systemPrompt, user: user)
            return Reply(kind: .text, text: OneThingAssistantGuardrails.enforce(raw))
        } catch {
            return Reply(kind: .text, text: OneThingAssistantGuardrails.enforce(ruleBasedReply(userText: userText, context: context)))
        }
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
                    Next: focus until you stop it, then mark done in Home.
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
        lower == "y" || lower == "yes" || lower == "start" || lower.contains("start")
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

    private func ruleBasedReply(userText: String, context: AssistantContext?) -> String {
        let lower = userText.lowercased()

        if lower.contains("what should i put") || lower.contains("one thing") || lower.contains("task") {
            return """
            Pick one concrete action you can finish today.
            Make it small and specific.
            What’s the outcome you want by the end?
            """
        }

        if lower.contains("rewrite") || lower.contains("make it") || lower.contains("simpler") {
            return """
            Write it as one action.
            Example: “Draft the first paragraph.”
            What’s your current wording?
            """
        }

        if lower.contains("how") || lower.contains("works") || lower.contains("why") {
            return """
            OneThing keeps it to one task so the next step is obvious.
            Start the timer when you begin, stop when you pause, then mark done.
            History is just a small record, not a score.
            What part should I explain?
            """
        }

        if let context {
            return nextStepFromContext(context)
        }

        return """
        Let’s keep it simple.
        Write one task for today, then start the timer.
        What’s the one thing you want to do?
        """
    }

    private func nextStepFromContext(_ context: AssistantContext) -> String {
        if context.today.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return """
            Add your one task for today.
            Keep it as a single action.
            What do you want to write there?
            """
        }
        if context.today.completed {
            return """
            You marked it done.
            If you want another task, tap “Start Another Task”.
            """
        }
        if context.today.isRunning {
            return """
            The timer is running.
            Stop it when you’re done working, then mark done.
            """
        }
        return """
        Your task is set.
        Start the timer when you begin, or mark done when finished.
        """
    }

    private func encodeContext(_ context: AssistantContext) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? String(data: encoder.encode(context), encoding: .utf8)
    }
}
