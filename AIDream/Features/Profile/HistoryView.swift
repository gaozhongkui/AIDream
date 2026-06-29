import AVKit
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "History")

struct HistoryView: View {
    @ObservedObject var creationService = CreationService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .background(Color.white.opacity(0.03))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                    Spacer()
                    Text(NSLocalizedString("title_creative_history", comment: ""))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                if creationService.creations.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(creationService.creations) { item in
                                HistoryCard(item: item)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            logger.info("HistoryView appeared. Creations count: \(creationService.creations.count)")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.accentGlow)
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.accentGrad)
            }
            Text(NSLocalizedString("label_no_history", comment: ""))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            Text(NSLocalizedString("label_history_subtitle", comment: ""))
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
            Spacer()
        }
    }
}

// MARK: - Looped Video Player for Preview

struct LoopedVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(url: url)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.updateURL(url)
    }

    class PlayerUIView: UIView {
        private var playerLayer = AVPlayerLayer()
        private var player: AVPlayer?
        private var url: URL?

        init(url: URL) {
            self.url = url
            super.init(frame: .zero)
            setupPlayer()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        func updateURL(_ newURL: URL) {
            if url != newURL {
                url = newURL
                setupPlayer()
            }
        }

        private func setupPlayer() {
            guard let url = url else {
                logger.warning("LoopedVideoPlayer: URL is nil")
                return
            }
            logger.debug("Setting up player for URL: \(url.absoluteString)")
            player?.pause()

            var headers = [
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
            ]

            if url.absoluteString.contains("openrouter.ai") {
                let apiKey = AIConfig.shared.openRouterApiKey
                headers["Authorization"] = "Bearer \(apiKey)"
                headers["HTTP-Referer"] = "https://aidream.app"
                headers["X-Title"] = "AIDream"
            }

            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
            let item = AVPlayerItem(asset: asset)
            let player = AVPlayer(playerItem: item)
            player.isMuted = true // 列表预览静音
            player.preventsDisplaySleepDuringVideoPlayback = false

            self.player = player
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill

            if layer.sublayers?.contains(playerLayer) != true {
                layer.addSublayer(playerLayer)
            }

            NotificationCenter.default.addObserver(self, selector: #selector(reachEnd), name: .AVPlayerItemDidPlayToEndTime, object: item)
            player.play()
        }

        @objc private func reachEnd() {
            logger.debug("LoopedVideoPlayer: Video reached end, looping...")
            player?.seek(to: .zero)
            player?.play()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - History Card

struct HistoryCard: View {
    let item: CreationItem
    @State private var showDetail = false
    @State private var toastMessage: String?
    @State private var thumbnail: UIImage?

    var body: some View {
        Button {
            logger.info("HistoryCard: Opening detail for item \(item.id.uuidString)")
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // 预览区
                ZStack {
                    if item.type == .video, let url = item.availableURL {
                        // 视频自动播放预览
                        LoopedVideoPlayer(url: url)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    } else if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .clipped() // 显式裁剪掉 fill 模式下多余的部分
                    } else {
                        // 装饰光点
                        Circle()
                            .fill(AppTheme.accentPrimary.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .blur(radius: 20)

                        Image(systemName: item.type == .video ? "play.fill" : "photo.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.3))
                    }

                    // 媒体类型标签
                    VStack {
                        HStack {
                            Text(item.type == .video ? NSLocalizedString("label_video", comment: "") : NSLocalizedString("label_image", comment: ""))
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(item.type == .video ? Color.blue : Color.purple)
                                .cornerRadius(6)
                                .padding(10)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(0.75, contentMode: .fit) // 使用 .fit 确保宽度紧贴网格列宽
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#1A1D4A"), Color(hex: "#0E1030")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18)) // 整体形状裁剪
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )

                // 信息区
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.prompt)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.textMuted)
                        Text(item.displayDate)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onAppear { loadThumbnail() }
        .fullScreenCover(isPresented: $showDetail) {
            if let playURL = item.availableURL {
                VideoCompletionView(
                    media: item.type == .video ? .video(playURL) : .image(thumbnail ?? UIImage()),
                    onClose: { showDetail = false },
                    onRetake: {
                        CreationService.shared.deleteCreation(item)
                        showDetail = false
                    },
                    onDownload: { saveToLibrary() },
                    onShare: { shareMedia() },
                    isFromHistory: true
                )
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .background(Color.white.opacity(0.03))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { toastMessage = nil }
                        }
                    }
            }
        }
    }

    private func loadThumbnail() {
        guard let url = item.availableURL else {
            logger.error("HistoryCard: No available URL for item \(item.id.uuidString)")
            return
        }
        if item.type == .image {
            // 图片直接读取
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try Data(contentsOf: url)
                    if let img = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.thumbnail = img
                            logger.debug("Loaded image thumbnail for: \(item.id.uuidString)")
                        }
                    }
                } catch {
                    logger.error("Failed to load image data for \(item.id.uuidString): \(error.localizedDescription)")
                }
            }
        } else {
            // 视频提取首帧缩略图
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 400, height: 400) // 限制缩略图尺寸节省内存

            let time = CMTime(seconds: 0.0, preferredTimescale: 600)

            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, error in
                if let error = error {
                    logger.error("Failed to generate video thumbnail for \(item.id.uuidString): \(error.localizedDescription)")
                }
                if let image = image {
                    let uiImage = UIImage(cgImage: image)
                    DispatchQueue.main.async {
                        self.thumbnail = uiImage
                        logger.debug("Generated video thumbnail for: \(item.id.uuidString)")
                    }
                }
            }
        }
    }

    private func saveToLibrary() {
        guard let url = item.availableURL else { return }
        logger.info("Saving media to library: \(url.lastPathComponent)")
        if item.type == .video {
            if url.isFileURL {
                UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
            } else {
                // 如果是远程视频，跳转到详情页下载更好，或者这里提示不支持直接从预览保存
                toastMessage = NSLocalizedString("toast_download_from_player", comment: "")
                return
            }
        } else {
            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
            }
        }
        toastMessage = NSLocalizedString("toast_saved_to_gallery", comment: "")
    }

    private func shareMedia() {
        guard let url = item.availableURL else { return }
        logger.info("Sharing media: \(url.lastPathComponent)")
        let items: [Any] = item.type == .video ? [url] : [thumbnail ?? url]
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController
        {
            rootVC.present(av, animated: true)
        }
    }
}
