import SwiftUI

struct LaunchView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var glowOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // 背景
            AppTheme.bgPrimary.ignoresSafeArea()

            // 背景发光装饰
            Circle()
                .fill(AppTheme.accentGlow)
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .opacity(glowOpacity)

            VStack(spacing: 24) {
                // Logo 区域
                ZStack {
                    // 外圈发光
                    Circle()
                        .stroke(AppTheme.accentGrad, lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .opacity(logoOpacity * 0.5)
                        .scaleEffect(logoScale * 1.1)

                    Image(systemName: "wand.and.stars.inverse")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.accentGrad)
                        .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 15)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // 文字标题
                VStack(spacing: 8) {
                    Text("AI DREAM")
                        .font(.system(size: 32, weight: .black))
                        .tracking(8)
                        .foregroundStyle(AppTheme.accentGrad)

                    Text("VISIONARY CREATIVITY")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(4)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .offset(y: isActive ? 0 : 20)
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
                glowOpacity = 0.6
            }

            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.3)) {
                isActive = true
            }
        }
    }
}

#Preview {
    LaunchView()
}
