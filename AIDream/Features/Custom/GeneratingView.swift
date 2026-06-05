import SwiftUI

struct GeneratingView: View {
    var progress: Double
    var onBackToHome: () -> Void

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            // Core energy glow in background
            RadialGradient(
                colors: [AppTheme.accentPrimary.opacity(0.12), .clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Center futuristic container
                VStack(spacing: 32) {
                    ZStack {
                        // Progress Ring (Visual backdrop)
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 8)
                            .frame(width: 200, height: 200)

                        // Animated Lottie/Icon
                        LottieView(name: "ai_generating_a")
                            .frame(width: 140, height: 140)

                        // Active Progress Arc
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(
                                AppTheme.accentGrad,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear, value: progress)
                    }
                    .shadow(color: AppTheme.accentGlow, radius: 20)

                    VStack(spacing: 12) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.accentGrad)

                        Text("Synthesizing your vision...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(40)
                .glassStyle(cornerRadius: 40)
                .padding(.horizontal, 30)

                Spacer()

                // Bottom actions
                VStack(spacing: 20) {
                    Button(action: onBackToHome) {
                        HStack(spacing: 10) {
                            Image(systemName: "house.fill")
                            Text("Minimize to Background")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)

                    Text("We'll push a notification when the masterpiece is ready.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
    }
}
