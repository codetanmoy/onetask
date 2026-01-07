import Foundation
import SwiftData

/// Task suggestion service for reducing friction in the RESPONSE phase.
/// Analyzes history to suggest likely tasks based on patterns.
enum TaskSuggestionService {
    
    struct Suggestion: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let reason: SuggestionReason
        
        enum SuggestionReason {
            case yesterday      // Continue yesterday's task
            case frequent       // Frequently used task
            case verb           // Common verb suggestion
        }
    }
    
    /// Generate task suggestions based on history
    /// - Returns: Up to 3 suggestions
    static func generateSuggestions(context: ModelContext) throws -> [Suggestion] {
        var suggestions: [Suggestion] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        // Fetch recent entries
        let descriptor = FetchDescriptor<DayEntry>(
            sortBy: [SortDescriptor(\.day, order: .reverse)]
        )
        let entries = try context.fetch(descriptor)
        
        // 1. Yesterday's incomplete task (highest priority)
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            let yesterdayStart = calendar.startOfDay(for: yesterday)
            if let yesterdayEntry = entries.first(where: { 
                calendar.startOfDay(for: $0.day) == yesterdayStart && 
                !$0.taskText.isEmpty 
            }) {
                // If yesterday's task wasn't completed, suggest continuing it
                if !yesterdayEntry.isCompleted {
                    suggestions.append(Suggestion(
                        text: yesterdayEntry.taskText,
                        reason: .yesterday
                    ))
                }
            }
        }
        
        // 2. Most frequent tasks (top 2 that aren't already suggested)
        let taskCounts = Dictionary(grouping: entries.filter { !$0.taskText.isEmpty }) { 
            $0.taskText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) 
        }
        .mapValues { $0.count }
        .sorted { $0.value > $1.value }
        
        for (taskText, count) in taskCounts.prefix(5) where count >= 2 {
            // Find original casing from entries
            if let originalEntry = entries.first(where: { 
                $0.taskText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == taskText 
            }) {
                let text = originalEntry.taskText
                // Don't duplicate
                if !suggestions.contains(where: { $0.text.lowercased() == text.lowercased() }) {
                    suggestions.append(Suggestion(text: text, reason: .frequent))
                }
            }
            if suggestions.count >= 3 { break }
        }
        
        // 3. Common verb suggestions if we still have room
        let commonVerbs = ["Write", "Code", "Read", "Review", "Design", "Plan", "Fix", "Build"]
        for verb in commonVerbs where suggestions.count < 3 {
            // Only suggest verbs not already in suggestions
            if !suggestions.contains(where: { $0.text.lowercased().hasPrefix(verb.lowercased()) }) {
                suggestions.append(Suggestion(text: verb, reason: .verb))
            }
            if suggestions.count >= 3 { break }
        }
        
        return Array(suggestions.prefix(3))
    }
}
