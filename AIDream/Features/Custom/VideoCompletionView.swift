import SwiftUI
import AVKit

// MARK: - 完成结果媒体类型
enum CompletionMedia {
    case video(URL)
    case image(UIImage)
}

struct VideoCompletionView: View {
    var media: CompletionMedia
    var onClose: () -> Void
    var onRetake: () -> Void
    var onDownload: () -> Void
    var onShare: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#090909").ignoresSafeArea()

            // 背景金色光晕
            RadialGradient(
                colors: [Color(hex: "#D4A82A").opacity(0.07), .clear],
                center: .center, startRadius: 10, endRadius: 350
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── 顶部导航 ──
                navBar

                Spacer()

                // ── 媒体卡片 ──
                mediaCard
                    .shadow(color: Color(hex: "#D4A82A").opacity(0.25), radius: 35, x: 0, y: 15)

                Spacer()

                // ── 底部操作 ──
                actionBar
            }
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "#28282E"), lineWidth: 0.5))
            }

            Spacer()

            Text(navTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#F6C842"), Color(hex: "#C9920A")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            Spacer()

            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "#D4A82A"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#D4A82A").opacity(0.12))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "#D4A82A").opacity(0.4), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var navTitle: String {
        switch media {
        case .video: return "Video Created"
        case .image: return "Image Created"
        }
    }

    // MARK: - Media Card
    private var mediaCard: some View {
        ZStack {
            // 卡片背景 + 金色渐变边框
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(hex: "#17171F"))
                .frame(width: 240, height: 427)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#F6C842"),
                                    Color(hex: "#8B6A14"),
                                    Color(hex: "#F6C842").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            // 媒体内容
            switch media {
            case .video(let url):
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(width: 240, height: 427)
                    .clipShape(RoundedRectangle(cornerRadius: 32))

            case .image(let img):
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 240, height: 427)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
            }
        }
    }

    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: 12) {
            // Retake
            Button(action: onRetake) {
                VStack(spacing: 5) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .bold))
                    Text("Retake")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 62, height: 62)
                .background(Color.white.opacity(0.07))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "#28282E"), lineWidth: 0.5)
                )
            }

            // Download / Save
            Button(action: onDownload) {
                HStack(spacing: 8) {
                    Image(systemName: downloadIcon)
                        .font(.system(size: 17, weight: .bold))
                    Text(downloadLabel)
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(Color(hex: "#0A0A0A"))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#F6C842"), Color(hex: "#C9920A")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(22)
                .shadow(color: Color(hex: "#D4A82A").opacity(0.4), radius: 12, y: 5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 44)
    }

    private var downloadIcon: String {
        switch media {
        case .video: return "arrow.down.to.line"
        case .image: return "square.and.arrow.down"
        }
    }

    private var downloadLabel: String {
        switch media {
        case .video: return "Save Video"
        case .image: return "Save Image"
        }
    }
}
