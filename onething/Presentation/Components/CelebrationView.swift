import SwiftUI

/// Full-screen celebration overlay for milestone achievements.
/// Auto-dismisses after 3 seconds per psychology doc.
struct CelebrationView: View {
    let milestone: MilestoneService.Milestone
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var showConfetti = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .opacity(isVisible ? 1 : 0)
            
            VStack(spacing: 24) {
                // Celebration emoji/icon
                Text(milestone.title.prefix(2)) // Get emoji
                    .font(.system(size: 80))
                    .scaleEffect(showConfetti ? 1.0 : 0.3)
                    .opacity(showConfetti ? 1 : 0)
                
                VStack(spacing: 12) {
                    Text(String(milestone.title.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(milestone.message)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
            }
        }
        .onAppear {
            // Animate entrance
            let animDuration = reduceMotion ? 0.1 : 0.4
            withAnimation(.easeOut(duration: animDuration)) {
                isVisible = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                showConfetti = true
            }
            
            // Auto-dismiss after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    withAnimation(.easeIn(duration: animDuration)) {
                        isVisible = false
                    }
                }
                try? await Task.sleep(nanoseconds: UInt64(animDuration * 1_000_000_000))
                await MainActor.run {
                    onDismiss()
                }
            }
        }
        .onTapGesture {
            // Allow early dismissal
            withAnimation(.easeIn(duration: 0.2)) {
                isVisible = false
            }
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    CelebrationView(milestone: .streak7) { }
}
