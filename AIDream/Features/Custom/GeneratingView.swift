import SwiftUI

struct GeneratingView: View {
    var progress: Double
    var onBackToHome: () -> Void

    var body: some View {
        ZStack {
            // 背景 - id: ECLB2
            Color(hex: "#0c0c0c").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 1. 中心生成卡片 - id: okiAM / QiREB
                ZStack {
                    // 卡片背景与毛玻璃
                    RoundedRectangle(cornerRadius: 35)
                        .fill(Color(hex: "#46434e").opacity(0.6))
                        .background(.ultraThinMaterial)
                        .cornerRadius(35)
                        .frame(width: 240, height: 427)
                        // 渐变边框
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "#fc98ff"), Color(hex: "#95d7ff")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )

                    VStack(spacing: 30) {
                        // 核心动画：ai_generating_a.json
                        LottieView(name: "ai_generating_a")
                            .frame(width: 150, height: 150)

                        // 进度与文本
                        VStack(spacing: 12) {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("Generating...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .shadow(color: Color(hex: "#fc98ff").opacity(0.2), radius: 25, x: 0, y: 15)

                Spacer()

                // 2. 底部操作区
                VStack(spacing: 16) {
                    // 按钮 - id: AEw5a
                    Button(action: onBackToHome) {
                        Text("Back to Home")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 335, height: 60)
                            .background(Color(hex: "#868095").opacity(0.2))
                            .cornerRadius(20)
                    }

                    // 提示文字 - id: xbosi
                    Text("You can leave safely. We'll notify you when it's done.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
