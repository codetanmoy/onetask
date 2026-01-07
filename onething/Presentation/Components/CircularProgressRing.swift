import SwiftUI

/// A minimal circular progress ring - pure black/white theme
struct CircularProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let isRunning: Bool
    let lineWidth: CGFloat
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0
    
    init(progress: Double, isRunning: Bool = false, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.isRunning = isRunning
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color(.systemGray5),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Progress ring - simple black/white
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    Color.primary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: progress)
            
            // Subtle glow when running
            if isRunning {
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        Color.primary,
                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .opacity(0.2)
            }
        }
        .onAppear {
            if isRunning && !reduceMotion {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
        .onChange(of: isRunning) { _, running in
            if running && !reduceMotion {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                rotation = 0
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
