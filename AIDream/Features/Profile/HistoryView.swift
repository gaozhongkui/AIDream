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
                        LazyVStack(spacing: 14) {
                            ForEach(creationService.creations) { item in
                                HistoryCard(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
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

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: 0) {
                // 左侧预览区
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1A1D4A"), Color(hex: "#0E1030")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 120)

                    // 装饰光点
                    Circle()
                        .fill(AppTheme.accentPrimary.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .blur(radius: 15)

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .offset(x: 1)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )

                // 右侧信息
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.prompt)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textMuted)
                        Text(item.displayDate)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(.leading, 16)
                .padding(.vertical, 14)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.trailing, 4)
            }
            .padding(12)
            .glassStyle(cornerRadius: 22)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showDetail) {
            VideoCompletionView(
                media: .video(item.videoURL),
                onClose: { showDetail = false },
                onRetake: { showDetail = false },
                onDownload: { saveToLibrary() },
                onShare: { shareVideo() }
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

    private func saveToLibrary() {
        let path = item.videoURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            toastMessage = "File not found"
            return
        }
        UISaveVideoAtPathToSavedPhotosAlbum(path, nil, nil, nil)
        toastMessage = "Saved to gallery"
    }

    private func shareVideo() {
        let url = item.videoURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            toastMessage = "File not found"
            return
        }
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}
