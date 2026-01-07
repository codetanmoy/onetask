import SwiftUI

/// Suggestion chips for quick task input
struct TaskSuggestionChips: View {
    let suggestions: [TaskSuggestionService.Suggestion]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions) { suggestion in
                    Button {
                        onSelect(suggestion.text)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: iconFor(suggestion.reason))
                                .font(.caption2)
                            
                            Text(suggestion.text)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(colorFor(suggestion.reason))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(colorFor(suggestion.reason).opacity(0.12))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func iconFor(_ reason: TaskSuggestionService.Suggestion.SuggestionReason) -> String {
        switch reason {
        case .yesterday: return "arrow.counterclockwise"
        case .frequent: return "repeat"
        case .verb: return "text.cursor"
        }
    }
    
    private func colorFor(_ reason: TaskSuggestionService.Suggestion.SuggestionReason) -> Color {
        switch reason {
        case .yesterday: return .primary
        case .frequent: return .primary
        case .verb: return .secondary
        }
    }
}

#Preview {
    TaskSuggestionChips(
        suggestions: [
            .init(text: "Write blog post", reason: .yesterday),
            .init(text: "Code review", reason: .frequent),
            .init(text: "Design", reason: .verb)
        ]
    ) { _ in }
    .padding()
}
