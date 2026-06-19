import SwiftUI
import AVKit

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
                    Text("Creative History")
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
            Text("No creations yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            Text("Your AI-generated masterpieces will appear here")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
            Spacer()
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
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                // 预览区
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1A1D4A"), Color(hex: "#0E1030")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(0.75, contentMode: .fit)

                    if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
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
                            Text(item.type == .video ? "VIDEO" : "IMAGE")
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
            VideoCompletionView(
                media: item.type == .video ? .video(item.fileURL) : .image(thumbnail ?? UIImage()),
                onClose: { showDetail = false },
                onRetake: { showDetail = false },
                onDownload: { saveToLibrary() },
                onShare: { shareMedia() }
            )
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
        if item.type == .image {
            if let data = try? Data(contentsOf: item.fileURL), let img = UIImage(data: data) {
                self.thumbnail = img
            }
        } else {
            // 对于视频，可以生成缩略图（略）
        }
    }

    private func saveToLibrary() {
        if item.type == .video {
            UISaveVideoAtPathToSavedPhotosAlbum(item.fileURL.path, nil, nil, nil)
        } else {
            if let data = try? Data(contentsOf: item.fileURL), let img = UIImage(data: data) {
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
            }
        }
        toastMessage = "Saved to gallery"
    }

    private func shareMedia() {
        let items: [Any] = item.type == .video ? [item.fileURL] : [thumbnail ?? item.fileURL]
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}
