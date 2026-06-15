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

            // HypeCut 紫色光晕装饰 — 多层椭圆模糊
            ZStack {
                // 大光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.accentPrimary.opacity(0.15), .clear],
                            center: .center, startRadius: 20, endRadius: 200
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(y: -100)

                // 中心光点
                Circle()
                    .fill(AppTheme.accentPrimary.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)

                // 底部光晕
                Circle()
                    .fill(AppTheme.accentSecondary.opacity(0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(y: 200)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Progress Ring + Animation
                VStack(spacing: 28) {
                    ZStack {
                        // 背景环
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 5)
                            .frame(width: 160, height: 160)

                        // Lottie 动画
                        LottieView(name: "ai_generating_a")
                            .frame(width: 100, height: 100)

                        // 紫色进度弧
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(
                                AppTheme.accentGrad,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: progress)
                    }
                    .shadow(color: AppTheme.accentGlow, radius: 24)

                    // 百分比
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accentGrad)

                    // 动态提示
                    Text(tips[tipIndex])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(height: 36)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id(tipIndex)
                        .animation(.easeInOut(duration: 0.5), value: tipIndex)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(hex: "#161418").opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
                )
                .padding(.horizontal, 30)

                Spacer()

                // 取消按钮
                Button(action: onBackToHome) {
                    Text("Cancel Generation")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#1A1629"))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.borderSubtle, lineWidth: 0.5))
                }
                .padding(.bottom, 16)

                // 底部提示
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
