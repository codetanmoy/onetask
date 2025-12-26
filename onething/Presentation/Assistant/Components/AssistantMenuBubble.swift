import SwiftUI

struct AssistantMenuBubble: View {
    @State private var animateIn: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What would you like to do?")
                    .font(.headline)
                Text("Reply with 1, 2, or 3.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                optionRow(number: "1", icon: "square.and.pencil", title: "Create task", subtitle: "Set a task name, then start the timer.")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                optionRow(number: "2", icon: "info.circle", title: "Details of task", subtitle: "See today’s task, status, and next step.")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                optionRow(number: "3", icon: "calendar", title: "Summary for a day", subtitle: "Pick a date and get a short recap.")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 1)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                animateIn = true
            }
        }
    }

    private func optionRow(number: String, icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(animateIn ? 1 : 0.65))
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)
            .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)

            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.18), lineWidth: 1)
        }
        .scaleEffect(animateIn ? 1 : 0.98)
        .opacity(animateIn ? 1 : 0.01)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: animateIn)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        AssistantMenuBubble()
            .padding()
    }
}

