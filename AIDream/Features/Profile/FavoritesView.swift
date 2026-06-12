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
                            .background(Circle().fill(Color.white.opacity(0.08)))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
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
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(favoriteService.favoriteVideos) { video in
                                FavoriteVideoCard(video: video)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
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
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.accentGrad)
            }
            Text("No inspirations yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            Text("Find something you like in Explore and save it here!")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
            Spacer()
        }
    }
}

// MARK: - Favorite Video Card
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
                // Cover image
                KFImage(video.coverURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(minHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Bottom gradient
                LinearGradient(
                    colors: [.clear, .clear, Color.black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Floating info
                VStack(alignment: .leading, spacing: 2) {
                    Text(video.title.lowercased() == "untitled" ? video.introduction : video.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Text("@\(video.userName)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))

                        Text("·")
                            .foregroundColor(Color.white.opacity(0.3))

                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(red: 1, green: 0.82, blue: 0.2))

                        Text(formatCount(video.starCount))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.07))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}
