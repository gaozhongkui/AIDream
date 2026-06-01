import SwiftUI
import AVKit

struct VideoCompletionView: View {
    var videoURL: URL
    var onClose: () -> Void
    var onRetake: () -> Void
    var onDownload: () -> Void
    var onShare: () -> Void

    var body: some View {
        ZStack {
            // 全屏背景 - id: ECLB2
            Color(hex: "#0c0c0c").ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 顶部导航栏 - id: rdfV7
                HStack {
                    // 关闭按钮 - id: VOdqC
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "#868095").opacity(0.2))
                            .clipShape(Circle())
                    }

                    Spacer()

                    // 标题 - id: zpl9E
                    Text("Trending Now")
                        .font(.custom("Outfit-Bold", size: 18))
                        .foregroundColor(.white)
                        .tracking(-0.5) // letterSpacing: -0.5

                    Spacer()

                    // 分享按钮 - id: F2UVQ
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "#868095").opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer()

                // 2. 核心视频展示容器 - id: okiAM / QiREB
                ZStack {
                    // 背景容器：毛玻璃 + 填充色 (#46434e99)
                    RoundedRectangle(cornerRadius: 35)
                        .fill(Color(hex: "#46434e").opacity(0.6))
                        .background(.ultraThinMaterial)
                        .cornerRadius(35)
                        .frame(width: 240, height: 427)
                        // 彩色渐变描边：fc98ff to 95d7ff
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

                    // 视频预览组件
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(width: 240, height: 427)
                        .clipShape(RoundedRectangle(cornerRadius: 35))
                }
                .shadow(color: Color(hex: "#fc98ff").opacity(0.15), radius: 30, x: 0, y: 15)

                Spacer()

                // 3. 底部操作按钮组 - id: nw7w1
                HStack(spacing: 12) {
                    // Retake (重新生成) - id: u81hex
                    Button(action: onRetake) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .bold))
                            Text("Retake")
                                .font(.custom("Outfit-SemiBold", size: 10)) // id: Rl18h
                        }
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#868095").opacity(0.2))
                        .cornerRadius(20)
                    }

                    // Download (保存视频) - id: e0CM4
                    Button(action: onDownload) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.to.line")
                                .font(.system(size: 18, weight: .bold))
                            Text("Download") // id: X96kNb
                                .font(.custom("Outfit-Bold", size: 18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#c260f5"), Color(hex: "#6034e4")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}
