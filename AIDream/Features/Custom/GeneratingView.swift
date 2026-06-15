import SwiftUI
import Combine

struct GeneratingView: View {
    var progress: Double
    var onBackToHome: () -> Void

    @State private var tipIndex: Int = 0
    private let tips = [
        "Crafting every frame with neural precision...",
        "AI is painting motion from your imagination...",
        "Polishing details, one pixel at a time...",
        "Translating your vision into reality...",
        "Almost there — greatness takes a moment...",
        "Weaving light and motion together...",
        "Your masterpiece is materializing..."
    ]

    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            // Core energy glow
            RadialGradient(
                colors: [AppTheme.accentPrimary.opacity(0.12), .clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Progress Ring + Lottie
                VStack(spacing: 32) {
                    ZStack {
                        // Background ring
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 6)
                            .frame(width: 180, height: 180)

                        // Animated icon
                        LottieView(name: "ai_generating_a")
                            .frame(width: 120, height: 120)

                        // Progress arc
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(
                                AppTheme.accentGrad,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: progress)
                    }
                    .shadow(color: AppTheme.accentGlow, radius: 20)

                    // Percentage
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.accentGrad)

                    // Dynamic tip
                    Text(tips[tipIndex])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(height: 40)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id(tipIndex)
                        .animation(.easeInOut(duration: 0.5), value: tipIndex)
                }
                .padding(36)
                .glassStyle(cornerRadius: 36)
                .padding(.horizontal, 30)

                Spacer()

                // Cancel button
                Button(action: onBackToHome) {
                    Text("Cancel Generation")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                }
                .padding(.bottom, 16)

                // Bottom hint
                Text("You can leave this screen — we'll keep working.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.bottom, 50)
            }
        }
        .onReceive(timer) { _ in
            withAnimation { tipIndex = (tipIndex + 1) % tips.count }
        }
    }
}
