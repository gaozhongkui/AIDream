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
                            .background(Circle().fill(Color.white.opacity(0.1)))
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
                        LazyVStack(spacing: 16) {
                            ForEach(creationService.creations) { item in
                                HistoryRow(item: item)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "video.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.accentGrad)
                .opacity(0.5)
            Text("No creations yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }
}

struct HistoryRow: View {
    let item: CreationItem
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: 16) {
                // Video Preview (Placeholder or generated thumb)
                ZStack {
                    Color.white.opacity(0.05)
                        .frame(width: 100, height: 140)
                        .cornerRadius(12)

                    Image(systemName: "play.fill")
                        .foregroundColor(.white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.prompt)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(item.displayDate)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted)

                    Spacer()
                }
                .padding(.vertical, 8)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(12)
            .glassStyle(cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showDetail) {
            VideoCompletionView(
                media: .video(item.videoURL),
                onClose: { showDetail = false },
                onRetake: { showDetail = false },
                onDownload: {},
                onShare: {}
            )
        }
    }
}
