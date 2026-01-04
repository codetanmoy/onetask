import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentPage: Int = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            title: "One Task",
            subtitle: "One Focus",
            description: "Stop juggling. Pick one thing and give it your full attention.",
            accentColor: .red
        ),
        OnboardingPage(
            icon: "timer",
            title: "Start Timer",
            subtitle: "Track Progress",
            description: "Simple timer runs while you work. See exactly where your time goes.",
            accentColor: .red
        ),
        OnboardingPage(
            icon: "checkmark.circle.fill",
            title: "Get It Done",
            subtitle: "Feel Accomplished",
            description: "Complete your task. Build momentum. Repeat tomorrow.",
            accentColor: .green
        )
    ]
    
    // Theme-aware colors
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }
    
    private var buttonBackgroundColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var buttonTextColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var indicatorInactiveColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Page content
                pageContent
                
                Spacer()
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? primaryTextColor : indicatorInactiveColor)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 48)
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            finishOnboarding()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                                .font(.headline.weight(.semibold))
                            
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .foregroundColor(buttonTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(buttonBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    if currentPage < pages.count - 1 {
                        Button {
                            finishOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 && currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else if value.translation.width > 50 && currentPage > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    }
                }
        )
    }
    
    private var pageContent: some View {
        VStack(spacing: 40) {
            // Icon
            ZStack {
                Circle()
                    .stroke(pages[currentPage].accentColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: pages[currentPage].icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(pages[currentPage].accentColor)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5), isActive: true)
            }
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            // Text content
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(primaryTextColor)
                    
                    Text(pages[currentPage].subtitle)
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(pages[currentPage].accentColor)
                }
                .multilineTextAlignment(.center)
                
                Text(pages[currentPage].description)
                    .font(.body)
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }
            .animation(.easeInOut(duration: 0.3), value: currentPage)
        }
        .padding(.horizontal, 32)
    }
    
    private func finishOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isComplete = true
        }
    }
}

// MARK: - Onboarding Page Model

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let accentColor: Color
}

#Preview("Light") {
    OnboardingView(isComplete: .constant(false))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingView(isComplete: .constant(false))
        .preferredColorScheme(.dark)
}
