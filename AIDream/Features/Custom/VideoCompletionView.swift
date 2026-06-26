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
        view.isUserInteractionEnabled = false // 禁止 UIView 拦截手势，让 SwiftUI 接管
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
    var isFromHistory: Bool = false

    @State private var player: AVPlayer?
    @State private var isPlayerReady = false
    @State private var playerError: String?
    @State private var playerObserver: NSKeyValueObservation?
    @State private var loopObserver: Any?
    @State private var isSavingToGallery = false
    @State private var toastMessage: String?

    @State private var localVideoURL: URL?
    @State private var isLoadingVideo = false

    // 缩放与位移状态
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @GestureState private var magnifyBy = 1.0

    var body: some View {
        ZStack {
            // 全屏媒体容器
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
                            Button(NSLocalizedString("btn_retry", comment: "")) { loadMedia() }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.accentSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else if isPlayerReady, let player = player {
                        FullScreenVideoPlayer(player: player)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleEffect(scale * magnifyBy)
                            .offset(offset)
                            .allowsHitTesting(false)
                    } else if case .image(let uiImage) = media {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleEffect(scale * magnifyBy)
                            .offset(offset)
                            .allowsHitTesting(false)
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(AppTheme.accentSecondary)
                                .scaleEffect(1.2)
                            Text(isLoadingVideo ? NSLocalizedString("state_downloading", comment: "") : NSLocalizedString("state_loading", comment: ""))
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.black)
                .contentShape(Rectangle())
                .gesture(
                    MagnificationGesture()
                        .updating($magnifyBy) { value, state, _ in
                            state = value
                        }
                        .onEnded { value in
                            scale *= value
                            // 限制缩放范围
                            scale = min(max(scale, 1.0), 5.0)
                            if scale <= 1.0 {
                                withAnimation(.spring()) {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
            .ignoresSafeArea()

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
            .allowsHitTesting(false) // 允许点击穿透

            // 底部渐变遮罩（操作栏区域）
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.55), Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 250) // 限制高度，避免遮挡中间手势
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false) // 允许点击穿透

            // 内容覆盖层
            ZStack {
                VStack {
                    navBar
                    Spacer()
                }

                VStack {
                    Spacer()
                    actionBar
                }
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
                        .background(.ultraThinMaterial)
                        .background(Color.white.opacity(0.03))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                        .padding(.bottom, 130)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
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
                    .background(.ultraThinMaterial)
                    .background(Color.white.opacity(0.03))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }

            Spacer()

            // 标题
            Text(NSLocalizedString("title_your_creation", comment: ""))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // 分享按钮
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .background(Color.white.opacity(0.03))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Action Bar（底部覆盖层）
    private var actionBar: some View {
        HStack(spacing: 10) {
            // Retake / Delete 按钮
            Button(action: onRetake) {
                VStack(spacing: 4) {
                    Image(systemName: isFromHistory ? "trash" :"square.and.pencil")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isFromHistory
                         ? NSLocalizedString("btn_delete", comment: "")
                         : NSLocalizedString("btn_retake", comment: ""))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(.ultraThinMaterial)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
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
                    Text(isSavingToGallery ? NSLocalizedString("state_saving", comment: "") : NSLocalizedString("btn_download", comment: ""))
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
                    let apiKey = AIConfig.shared.openRouterApiKey
                    print("[VideoCompletionView] Using API Key (first 10 chars): \(apiKey.prefix(10))...")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("https://aidream.app", forHTTPHeaderField: "HTTP-Referer")
                    request.setValue("AIDream", forHTTPHeaderField: "X-Title")
                }
                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

                let (tempURL, response) = try await session.download(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    throw NSError(domain: "Download", code: code, userInfo: [NSLocalizedDescriptionKey: String(format: NSLocalizedString("err_service_error", comment: ""), code)])
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
                    let err = item.error?.localizedDescription ?? NSLocalizedString("err_creation_failed", comment: "")
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
        // 仅删除 Caches 目录下的临时预览文件，避免误删 Documents 下的历史记录文件
        if let url = localVideoURL, url.path.contains("/Caches/") {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func handleDownload() {
        if let onDownload = onDownload { onDownload(); return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited {
                Task { await performSave() }
            } else { showToast(NSLocalizedString("err_no_permission", comment: "")) }
        }
    }

    private func performSave() async {
        DispatchQueue.main.async { isSavingToGallery = true; showToast(NSLocalizedString("state_saving", comment: "")) }
        do {
            // 优先使用下载好的临时文件，如果没有则看 media 是否本身就是本地文件
            let saveURL: URL
            if let local = localVideoURL {
                saveURL = local
            } else if case .video(let url) = media, url.isFileURL {
                saveURL = url
            } else {
                throw NSError(domain: "Save", code: -1, userInfo: [NSLocalizedDescriptionKey: "No local file to save"])
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: saveURL)
            }) { success, _ in
                DispatchQueue.main.async {
                    isSavingToGallery = false
                    showToast(success ? NSLocalizedString("state_saved", comment: "") : NSLocalizedString("err_failed", comment: ""))
                }
            }
        } catch {
            DispatchQueue.main.async { isSavingToGallery = false; showToast(NSLocalizedString("err_prefix", comment: "")) }
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
        if let nHost = newRequest.url?.host, !nHost.contains("openrouter.ai") {
            req.setValue(nil, forHTTPHeaderField: "Authorization")
        }
        completionHandler(req)
    }
}
