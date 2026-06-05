import SwiftUI
import Kingfisher

struct FavoritesView: View {
    @ObservedObject var favoriteService = FavoriteService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Nav Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }

                    Spacer()

                    Text("My Inspirations")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                if favoriteService.favoriteVideos.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(favoriteService.favoriteVideos) { video in
                                FavoriteVideoCard(video: video)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.accentGrad)
                .opacity(0.5)

            Text("No inspirations yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)

            Text("Go to Explore and find something you like!")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

struct FavoriteVideoCard: View {
    let video: VideoData

    var body: some View {
        Button {
            if let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController {
                let detailVC = VideoDetailViewController(videos: [video], initialIndex: 0)
                rootVC.present(detailVC, animated: true)
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                KFImage(video.coverURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Info Overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                    Text("@\(video.userName)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .buttonStyle(.plain)
    }
}
