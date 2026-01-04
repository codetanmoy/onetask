import SwiftUI

/// A premium circular progress ring with gradient stroke and smooth animations.
struct CircularProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let isRunning: Bool
    let lineWidth: CGFloat
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var gradientRotation: Double = 0
    
    init(progress: Double, isRunning: Bool = false, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.isRunning = isRunning
        self.lineWidth = lineWidth
    }
    
    private var gradientColors: [Color] {
        if isRunning {
            return [.green, .mint, .green]
        } else {
            return [.accentColor, .accentColor.opacity(0.6), .accentColor]
        }
    }
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color(.systemGray5),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(gradientRotation),
                        endAngle: .degrees(gradientRotation + 360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: progress)
            
            // Glow effect when running
            if isRunning {
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        gradientColors.first ?? .green,
                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 8)
                    .opacity(0.4)
            }
        }
        .onAppear {
            if isRunning && !reduceMotion {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    gradientRotation = 360
                }
            }
        }
        .onChange(of: isRunning) { _, running in
            if running && !reduceMotion {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    gradientRotation = 360
                }
            } else {
                gradientRotation = 0
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularProgressRing(progress: 0.65, isRunning: true)
            .frame(width: 120, height: 120)
        
        CircularProgressRing(progress: 0.3, isRunning: false)
            .frame(width: 120, height: 120)
    }
    .padding()
}
