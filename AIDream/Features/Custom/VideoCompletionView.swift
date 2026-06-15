import SwiftUI
import AVKit
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "Completion")

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
    @State private var isPlayerReady = false
    @State private var playerError: String?
    @State private var playerObserver: NSKeyValueObservation?

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            RadialGradient(
                colors: [AppTheme.accentPrimary.opacity(0.1), .clear],
                center: .top, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                Spacer()
                mediaCard
                    .shadow(color: AppTheme.accentGlow.opacity(0.2), radius: 30, y: 15)
                Spacer()
                actionBar
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { cleanupPlayer() }
    }

    // MARK: - Player Setup
    private func setupPlayer() {
        guard case .video(let url) = media else { return }

        logger.info("Initializing player for URL: \(url.absoluteString)")

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        // 监听播放状态
        playerObserver = playerItem.observe(\.status, options: [.new, .initial]) { [self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    logger.info("Player ready to play")
                    isPlayerReady = true
                    playerError = nil
                    player.play()
                case .failed:
                    let error = item.error?.localizedDescription ?? "Unknown error"
                    logger.error("Player failed: \(error)")
                    playerError = error
                    isPlayerReady = false
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        // 循环播放
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    private func cleanupPlayer() {
        player?.pause()
        playerObserver?.invalidate()
        playerObserver = nil
        player = nil
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
        case .video(_): return "SYNTHESIS READY"
        case .image(_): return "VISUAL RENDERED"
        }
    }

    // MARK: - Media Card
    private var mediaCard: some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width - 48, 340)
            let cardHeight = min(cardWidth * 1.6, geo.size.height * 0.6)

            ZStack {
                switch media {
                case .video(_):
                    if let error = playerError {
                        // 播放失败
                        VStack(spacing: 16) {
                            Image(systemName: "play.slash")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.error.opacity(0.6))
                            Text("Playback failed")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.error)
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            Button("Retry") {
                                cleanupPlayer()
                                playerError = nil
                                isPlayerReady = false
                                setupPlayer()
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.accentSecondary)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                    } else if isPlayerReady, let player = player {
                        // 正常播放
                        VideoPlayer(player: player)
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                            .frame(width: cardWidth, height: cardHeight)
                    } else {
                        // 加载中
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(AppTheme.accentSecondary)
                                .scaleEffect(1.2)
                            Text("Loading video...")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .background(Color.black.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                    }

                case .image(let img):
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                }

                // 边框 + 扫描线效果
                RoundedRectangle(cornerRadius: 32)
                    .stroke(AppTheme.accentGrad, lineWidth: 1.5)
                    .frame(width: cardWidth, height: cardHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: 16) {
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
        case .video(_): return "arrow.down.circle.fill"
        case .image(_): return "arrow.down.to.line.circle.fill"
        }
    }

    private var downloadLabel: String {
        switch media {
        case .video(_): return "Save to Vault"
        case .image(_): return "Export Image"
        }
    }
}
