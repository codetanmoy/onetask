import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pageIndex: Int = 0
    @State private var symbolVisible: Bool = false
    @State private var textVisible: Bool = false
    @State private var revealedSteps: Int = 0
    @State private var animationTask: Task<Void, Never>?

    private let steps: [OnboardingStep] = [
        .init(symbol: .sf("square.and.pencil"), text: "Pick one task"),
        .init(symbol: .text("•", size: 18), text: "Start the timer"),
        .init(symbol: .text("✓", size: 20), text: "Mark it done")
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                Spacer()
                symbol
                    .scaleEffect(symbolVisible ? 1 : 0.96)
                    .opacity(symbolVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.2), value: symbolVisible)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    Text(pageTitle)
                        .font(.largeTitle.weight(.semibold))
                        .multilineTextAlignment(.center)

                    if pageIndex == 0 {
                        Text("Finish one thing today.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(textVisible ? 1 : 0)
                            .offset(y: textVisible ? 0 : 12)
                            .animation(.easeOut(duration: 0.22), value: textVisible)
                    } else {
                        VStack(spacing: 18) {
                            ForEach(steps.indices, id: \.self) { index in
                                StepRow(step: steps[index])
                                    .opacity(revealedSteps > index ? 1 : 0)
                                    .offset(y: revealedSteps > index ? 0 : 8)
                                    .animation(.easeOut(duration: 0.22).delay(Double(index) * 0.08), value: revealedSteps)
                            }

                            Text("No lists. No planning.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .opacity(textVisible ? 1 : 0)
                                .offset(y: textVisible ? 0 : 8)
                                .animation(.easeOut(duration: 0.22), value: textVisible)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: 360)

                Spacer()

                footerButtons
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            scheduleAnimations()
        }
        .onChange(of: pageIndex) { _ in
            scheduleAnimations()
        }
    }

    private var symbol: some View {
        Group {
            if pageIndex == 0 {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 88, weight: .regular))
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 52, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var pageTitle: String {
        pageIndex == 0 ? "One task. One timer." : "That’s it."
    }

    private var footerButtons: some View {
        HStack(spacing: 16) {
            Button {
                finishOnboarding()
            } label: {
                Text("Skip")
                    .font(.callout.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
            }

            Button {
                primaryAction()
            } label: {
                Text(primaryButtonTitle)
                    .font(.callout.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
    }

    private var primaryButtonTitle: String {
        pageIndex == 0 ? "Continue" : "Start"
    }

    private func primaryAction() {
        if pageIndex == 0 {
            withAnimation(.easeInOut(duration: 0.26)) {
                pageIndex = 1
            }
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        animationTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            isComplete = true
        }
    }

    private func scheduleAnimations() {
        symbolVisible = false
        textVisible = false
        revealedSteps = reduceMotion ? steps.count : 0
        animationTask?.cancel()

        if reduceMotion {
            symbolVisible = true
            textVisible = true
            return
        }

        animationTask = Task.detached(priority: .userInitiated) { @MainActor in
            symbolVisible = true
            try? await Task.sleep(nanoseconds: 120_000_000)
            textVisible = true
            if pageIndex == 1 {
                for index in steps.indices {
                    if Task.isCancelled { return }
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    revealedSteps = index + 1
                }
            }
        }
    }
}

private struct StepRow: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 14) {
            step.symbol.view
                .font(.system(size: step.symbol.size, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32, alignment: .center)

            Text(step.text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

private struct OnboardingStep {
    let symbol: OnboardingStepSymbol
    let text: String
}

private struct OnboardingStepSymbol {
    let type: SymbolType
    let size: CGFloat

    var view: some View {
        switch type {
        case let .sf(name):
            AnyView(Image(systemName: name))
        case let .text(content):
            AnyView(Text(content))
        }
    }

    enum SymbolType {
        case sf(String)
        case text(String)
    }

    static func sf(_ name: String, size: CGFloat = 20) -> OnboardingStepSymbol {
        .init(type: .sf(name), size: size)
    }

    static func text(_ content: String, size: CGFloat = 20) -> OnboardingStepSymbol {
        .init(type: .text(content), size: size)
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}
