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

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            // Aurora Background Glow
            RadialGradient(
                colors: [AppTheme.accentPrimary.opacity(0.1), .clear],
                center: .top, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Modern Nav Bar ──
                navBar

                Spacer()

                // ── Futuristic Media Card ──
                mediaCard
                    .shadow(color: AppTheme.accentGlow.opacity(0.2), radius: 30, y: 15)

                Spacer()

                // ── Glass Action Bar ──
                actionBar
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func setupPlayer() {
        if case .video(let url) = media {
            print("🎬 [CompletionView] Initializing player for local URL: \(url.path)")
            let player = AVPlayer(url: url)
            self.player = player

            // Loop playback
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
            }

            player.play()
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }

            Spacer()

            Text(navTitle)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.accentGradH)

            Spacer()

            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.accentPrimary.opacity(0.2)))
                    .overlay(Circle().stroke(AppTheme.accentPrimary.opacity(0.4), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var navTitle: String {
        switch media {
        case .video: return "SYNTHESIS READY"
        case .image: return "VISUAL RENDERED"
        }
    }

    // MARK: - Media Card
    private var mediaCard: some View {
        ZStack {
            // Content
            Group {
                switch media {
                case .video:
                    if let player = player {
                        VideoPlayer(player: player)
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                    } else {
                        ProgressView().tint(.white)
                    }
                case .image(let img):
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                }
            }
            .frame(width: 280, height: 480)
            .primaryBorder(cornerRadius: 32, active: true)

            // Subtle Scanline Effect
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color.white.opacity(0.03), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 100)
                .offset(y: -150)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: 16) {
            // Retake Button (Glass Style)
            Button(action: onRetake) {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 20, weight: .bold))
                    Text("REMIX")
                        .font(.system(size: 10, weight: .black))
                }
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .glassStyle(cornerRadius: 22)
            }

            // Save Button (Aurora Gradient)
            Button(action: onDownload) {
                HStack(spacing: 12) {
                    Image(systemName: downloadIcon)
                        .font(.system(size: 18, weight: .bold))
                    Text(downloadLabel)
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(AppTheme.accentGradH)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: AppTheme.accentGlow, radius: 15, y: 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 44)
    }

    private var downloadIcon: String {
        switch media {
        case .video: return "arrow.down.circle.fill"
        case .image: return "arrow.down.to.line.circle.fill"
        }
    }

    private var downloadLabel: String {
        switch media {
        case .video: return "Save to Vault"
        case .image: return "Export Image"
        }
    }
}
