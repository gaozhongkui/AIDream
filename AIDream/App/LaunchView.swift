import SwiftUI

struct LaunchView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // 深邃星空背景
            Color(hex: "#05050C").ignoresSafeArea()

            // 动态星光
            StarFieldView()

            VStack(spacing: 60) {
                // 核心视觉组件
                ZStack {
                    // 背景光晕
                    Circle()
                        .fill(Color(hex: "#6F31D5").opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)

                    // 1. 最外层辅助圆环
                    Circle()
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                        .frame(width: 280, height: 280)

                    // 2. 动态旋转轨道 (带播放按钮)
                    ZStack {
                        // 轨道线
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#A07BFF").opacity(0.3), .clear, Color(hex: "#2EB5FF").opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.2
                            )
                            .frame(width: 200, height: 200)

                        // 轨道上的播放按钮
                        PlayButtonNode()
                            .offset(x: 100 * cos(Double.pi * 0.1), y: 100 * sin(Double.pi * 0.1))
                    }
                    .rotationEffect(.degrees(rotationAngle))

                    // 3. 中间装饰轨道
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [Color(hex: "#2EB5FF").opacity(0.4), .clear, Color(hex: "#A07BFF").opacity(0.4), .clear]),
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 150, height: 150)

                    // 4. 内层装饰轨道
                    Circle()
                        .stroke(
                            LinearGradient(colors: [Color(hex: "#2EB5FF").opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                        .frame(width: 110, height: 110)

                    // 5. 中心核心球体 (星球)
                    CoreSphereView()
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)

                // 品牌文本
                VStack(spacing: 16) {
                    Text("AI DREAM")
                        .font(.system(size: 40, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)

                    Text("VISIONARY CREATIVITY")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(5)
                        .foregroundColor(Color(hex: "#2EB5FF").opacity(0.8))
                }
                .offset(y: isAnimating ? 0 : 30)
                .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8, blendDuration: 0)) {
                isAnimating = true
            }
            // 缓慢的轨道旋转
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - 子组件: 中心核心球体
struct CoreSphereView: View {
    var body: some View {
        ZStack {
            // 球体主体
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color(hex: "#A07BFF"), Color(hex: "#6F31D5")]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 56, height: 56)
                .shadow(color: Color(hex: "#6F31D5").opacity(0.7), radius: 20)

            // 顶部高光
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: 20, height: 20)
                .offset(x: -12, y: -12)
                .blur(radius: 1)
        }
    }
}

// MARK: - 子组件: 轨道播放按钮
struct PlayButtonNode: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2EB5FF"), Color(hex: "#A07BFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .shadow(color: Color(hex: "#2EB5FF").opacity(0.5), radius: 12)

            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .offset(x: 2) // 视觉修正居中
        }
    }
}

// MARK: - 子组件: 星空背景
struct StarFieldView: View {
    @State private var opacity: Double = 0.5

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 静态微星
                ForEach(0..<60) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.5)))
                        .frame(width: CGFloat.random(in: 0.5...2))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                }

                // 闪烁的星芒
                ForEach(0..<8) { _ in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 10...18)))
                        .foregroundColor(.white.opacity(opacity))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 1.5...3.0))
                                .repeatForever(autoreverses: true),
                            value: opacity
                        )
                }
            }
        }
        .onAppear {
            opacity = 1.0
        }
    }
}

#Preview {
    LaunchView()
}
