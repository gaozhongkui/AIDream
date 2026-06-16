import SwiftUI
import AVKit
import OSLog
import AVFoundation
import Photos

private let logger = Logger(subsystem: "com.aidream", category: "Completion")

// MARK: - 全屏视频播放器（UIViewRepresentable，videoGravity = .resizeAspectFill）

/// 自定义 UIView，在 layoutSubviews 时自动同步 playerLayer.frame
fileprivate final class PlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer? {
        didSet { oldValue?.removeFromSuperlayer(); if let layer = playerLayer { self.layer.addSublayer(layer) } }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

fileprivate struct FullScreenVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .black
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer = playerLayer
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer?.player !== player {
            uiView.playerLayer?.player = player
        }
    }
}

// MARK: - CompletionMedia
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

    @State private var localVideoURL: URL?
    @State private var isLoadingVideo = false

    var body: some View {
        ZStack {
            // 全屏视频播放器
            GeometryReader { geo in
                ZStack {
                    if let error = playerError {
                        // 错误状态
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.error)
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding()
                            Button("Retry") { loadMedia() }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.accentSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else if isPlayerReady, let player = player {
                        FullScreenVideoPlayer(player: player)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else if case .image(let uiImage) = media {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(AppTheme.accentSecondary)
                                .scaleEffect(1.2)
                            Text(isLoadingVideo ? "Downloading..." : "Loading...")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
            .background(Color.black)

            // 顶部渐变遮罩（状态栏区域）
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .ignoresSafeArea(edges: .top)
                Spacer()
            }

            // 底部渐变遮罩（操作栏区域，延伸到最底部）
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.55), Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .bottom)

            // 内容覆盖层
            VStack(spacing: 0) {
                navBar
                Spacer()
                actionBar
            }
            
            // Toast 消息
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8).clipShape(Capsule()))
                        .padding(.bottom, 130)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { loadMedia() }
        .onDisappear { cleanupPlayer() }
    }

    // MARK: - Navigation Bar（覆盖层）
    private var navBar: some View {
        HStack {
            // 关闭按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }

            Spacer()

            // 标题
            Text("Trending Now")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // 分享按钮
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Action Bar（底部覆盖层）
    private var actionBar: some View {
        HStack(spacing: 10) {
            // Retake 按钮
            Button(action: onRetake) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Retake")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.15))
                )
            }

            // Download 按钮
            Button(action: handleDownload) {
                HStack(spacing: 10) {
                    if isSavingToGallery {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 18, weight: .bold))
                    }
                    Text(isSavingToGallery ? "Saving..." : "Download")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(AppTheme.accentGradH)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .disabled(isSavingToGallery || isLoadingVideo)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 44)
    }

    // MARK: - Player & Media Logic
    private func loadMedia() {
        switch media {
        case .video(let url):
            if url.isFileURL {
                setupPlayer(with: url)
            } else {
                downloadAndPlay(url: url)
            }
        case .image:
            break
        }
    }

    private func downloadAndPlay(url: URL) {
        isLoadingVideo = true
        playerError = nil

        Task {
            do {
                print("[VideoCompletionView] Starting download for: \(url.absoluteString)")
                let delegate = RedirectHandler()
                let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

                var request = URLRequest(url: url, timeoutInterval: 30)

                if url.absoluteString.contains("openrouter.ai") {
                    request.setValue("Bearer \(AIConfig.shared.openRouterApiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("https://aidream.app", forHTTPHeaderField: "HTTP-Referer")
                    request.setValue("AIDream", forHTTPHeaderField: "X-Title")
                }
                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

                let (tempURL, response) = try await session.download(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    throw NSError(domain: "Download", code: code, userInfo: [NSLocalizedDescriptionKey: "Server returned error \(code)"])
                }

                let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let localURL = caches.appendingPathComponent("preview_\(UUID().uuidString).mp4")

                if FileManager.default.fileExists(atPath: localURL.path) {
                    try? FileManager.default.removeItem(at: localURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: localURL)

                print("[VideoCompletionView] Download success: \(localURL.path)")

                DispatchQueue.main.async {
                    self.isLoadingVideo = false
                    self.localVideoURL = localURL
                    self.setupPlayer(with: localURL)
                }
            } catch {
                print("[VideoCompletionView] Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingVideo = false
                    self.playerError = error.localizedDescription
                }
            }
        }
    }

    private func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        playerObserver = playerItem.observe(\.status, options: [.new, .initial]) { [self] item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    print("[VideoCompletionView] Player Ready")
                    isPlayerReady = true
                    playerError = nil
                    player.play()
                } else if item.status == .failed {
                    let err = item.error?.localizedDescription ?? "Play failed"
                    print("[VideoCompletionView] Player Failed: \(err)")
                    playerError = err
                    isPlayerReady = false
                }
            }
        }

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem, queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    private func cleanupPlayer() {
        player?.pause()
        playerObserver?.invalidate()
        if let observer = loopObserver { NotificationCenter.default.removeObserver(observer) }
        player = nil
        if let url = localVideoURL { try? FileManager.default.removeItem(at: url) }
    }

    private func handleDownload() {
        if let onDownload = onDownload { onDownload(); return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
                Task { await performSave() }
            } else { showToast("No Permission") }
        }
    }

    private func performSave() async {
        DispatchQueue.main.async { isSavingToGallery = true; showToast("Saving...") }
        do {
            guard let url = localVideoURL else { throw NSError(domain: "Save", code: -1) }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, _ in
                DispatchQueue.main.async {
                    isSavingToGallery = false
                    showToast(success ? "Saved!" : "Failed")
                }
            }
        } catch {
            DispatchQueue.main.async { isSavingToGallery = false; showToast("Error") }
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { toastMessage = nil } }
    }
}

// MARK: - Redirect Handler
final class RedirectHandler: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        var req = newRequest
        if let oHost = task.originalRequest?.url?.host, let nHost = newRequest.url?.host, oHost != nHost {
            req.setValue(nil, forHTTPHeaderField: "Authorization")
        }
        completionHandler(req)
    }
}