import SwiftUI
import AVKit
import OSLog
import AVFoundation
import Photos

private let logger = Logger(subsystem: "com.aidream", category: "Completion")

enum CompletionMedia {
    case video(URL)
    case image(UIImage)
}

struct VideoCompletionView: View {
    var media: CompletionMedia
    var onClose: () -> Void
    var onRetake: () -> Void
    var onDownload: (() -> Void)? = nil
    var onShare: () -> Void

    @State private var player: AVPlayer?
    @State private var isPlayerReady = false
    @State private var playerError: String?
    @State private var playerObserver: NSKeyValueObservation?
    @State private var loopObserver: Any?
    @State private var isSavingToGallery = false
    @State private var toastMessage: String?

    // 存储本地临时路径，避开 AVPlayer 复杂的网络鉴权及重定向问题
    @State private var localVideoURL: URL?
    @State private var isLoadingVideo = false

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

            if let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8).clipShape(Capsule()))
                        .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear { loadMedia() }
        .onDisappear { cleanupPlayer() }
    }

    // MARK: - 媒体加载逻辑
    private func loadMedia() {
        guard case .video(let url) = media else { return }

        logger.info("[VideoCompletionView] STEP 1: loadMedia called for URL: \(url.absoluteString)")

        if url.isFileURL {
            logger.info("[VideoCompletionView] Media is already a local file.")
            setupPlayer(with: url)
            return
        }

        downloadAndPlay(url: url)
    }

    private func downloadAndPlay(url: URL) {
        isLoadingVideo = true
        playerError = nil

        Task {
            do {
                logger.info("[VideoCompletionView] STEP 2: Starting stable download with RedirectHandler...")

                var request = URLRequest(url: url, timeoutInterval: 45)
                if url.absoluteString.contains("openrouter.ai") {
                    request.setValue("Bearer \(AIConfig.shared.openRouterApiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("https://aidream.app", forHTTPHeaderField: "HTTP-Referer")
                    request.setValue("AIDream", forHTTPHeaderField: "X-Title")
                }
                // 增加更多的 Header 以模拟浏览器行为，避开 CDN 拦截
                request.setValue("video/mp4, */*", forHTTPHeaderField: "Accept")
                request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

                let delegate = RedirectHandler()
                // 使用系统最稳定的 download 接口
                let (tempLocalURL, response) = try await URLSession.shared.download(for: request, delegate: delegate)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "Playback", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }

                logger.info("[VideoCompletionView] STEP 3: Download finished. Status code: \(httpResponse.statusCode)")

                if httpResponse.statusCode != 200 {
                    throw NSError(domain: "Playback", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
                }

                // 移动到 Caches 目录
                let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let persistentURL = caches.appendingPathComponent("preview_\(UUID().uuidString).mp4")

                try? FileManager.default.removeItem(at: persistentURL)
                try FileManager.default.moveItem(at: tempLocalURL, to: persistentURL)

                logger.info("[VideoCompletionView] STEP 4: Saved to local path: \(persistentURL.path)")

                DispatchQueue.main.async {
                    self.isLoadingVideo = false
                    self.localVideoURL = persistentURL
                    self.setupPlayer(with: persistentURL)
                }
            } catch {
                logger.error("[VideoCompletionView] ERROR during download: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingVideo = false
                    self.playerError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Player Setup
    private func setupPlayer(with url: URL) {
        logger.info("[VideoCompletionView] STEP 5: setupPlayer called with LOCAL URL: \(url.path)")

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        playerObserver = playerItem.observe(\.status, options: [.new, .initial]) { [self] item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    logger.info("[VideoCompletionView] STEP 6: Player READY to play.")
                    isPlayerReady = true
                    playerError = nil
                    player.play()
                } else if item.status == .failed {
                    let err = item.error?.localizedDescription ?? "Playback failed"
                    logger.error("[VideoCompletionView] STEP 6: Player FAILED: \(err)")
                    playerError = err
                    isPlayerReady = false
                }
            }
        }

        loopObserver = NotificationCenter.default.addObserver(
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
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        loopObserver = nil
        player = nil

        if let localURL = localVideoURL {
            try? FileManager.default.removeItem(at: localURL)
            localVideoURL = nil
        }
    }

    // MARK: - 下载保存逻辑
    private func handleDownload() {
        if let onDownload = onDownload {
            onDownload()
            return
        }
        guard case .video(_) = media else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
                Task { await performSaveToGallery() }
            } else { showToast("Permission Denied") }
        }
    }

    private func performSaveToGallery() async {
        DispatchQueue.main.async { isSavingToGallery = true; showToast("Saving...") }
        do {
            let fileURL: URL
            if let local = localVideoURL {
                fileURL = local
            } else if case .video(let remoteURL) = media {
                let (data, _) = try await URLSession.shared.data(from: remoteURL)
                let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                try data.write(to: temp)
                fileURL = temp
            } else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }) { success, error in
                DispatchQueue.main.async {
                    isSavingToGallery = false
                    showToast(success ? "Saved to Gallery!" : "Save Failed")
                }
            }
        } catch {
            DispatchQueue.main.async { isSavingToGallery = false; showToast("Save error") }
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }

    // MARK: - UI Components
    private var navBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white).frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            Spacer()
            Text("SYNTHESIS READY")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AppTheme.accentGradH)
            Spacer()
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white).frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.accentPrimary.opacity(0.2)))
            }
        }
        .padding(.horizontal, 20).padding(.top, 12)
    }

    private var mediaCard: some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width - 48, 340)
            let cardHeight = min(cardWidth * 1.6, geo.size.height * 0.6)
            ZStack {
                if let error = playerError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 40)).foregroundColor(AppTheme.error)
                        Text(error).font(.system(size: 12)).foregroundColor(AppTheme.textMuted).multilineTextAlignment(.center).padding(.horizontal)
                        Button("Retry") { loadMedia() }
                            .font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.accentSecondary)
                    }
                } else if isPlayerReady, let player = player {
                    VideoPlayer(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                } else {
                    VStack(spacing: 16) {
                        ProgressView().tint(AppTheme.accentSecondary).scaleEffect(1.2)
                        Text(isLoadingVideo ? "Downloading video..." : "Preparing video...")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                RoundedRectangle(cornerRadius: 32)
                    .stroke(AppTheme.accentGrad, lineWidth: 1.5)
            }
            .frame(width: cardWidth, height: cardHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 16) {
            Button(action: onRetake) {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 20, weight: .bold))
                    Text("REMIX").font(.system(size: 10, weight: .black))
                }
                .foregroundColor(.white).frame(width: 72, height: 72).glassStyle(cornerRadius: 22)
            }

            Button(action: handleDownload) {
                HStack(spacing: 12) {
                    if isSavingToGallery {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill").font(.system(size: 18, weight: .bold))
                    }
                    Text(isSavingToGallery ? "SAVING..." : "Save to Vault").font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 72)
                .background(AppTheme.accentGradH).clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .disabled(isSavingToGallery || isLoadingVideo)
        }
        .padding(.horizontal, 24).padding(.bottom, 44)
    }
}

// MARK: - 🟢 处理 OpenRouter 重定向的专用类 (修复鉴权头冲突)
final class RedirectHandler: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        var redirectedRequest = newRequest

        // 如果重定向到了不同的主机（例如从 openrouter.ai 到 s3.amazonaws.com）
        // 必须移除 Authorization 头，否则云存储服务器会报 400/403 Invalid Request
        if let originalHost = task.originalRequest?.url?.host,
           let newHost = newRequest.url?.host,
           originalHost != newHost {
            logger.info("[RedirectHandler] host changed: \(originalHost) -> \(newHost). Removing Authorization header.")
            redirectedRequest.removeValue(forHTTPHeaderField: "Authorization")
        }

        completionHandler(redirectedRequest)
    }
}
