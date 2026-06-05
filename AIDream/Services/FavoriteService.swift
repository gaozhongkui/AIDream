import Foundation
import Combine

@MainActor
final class FavoriteService: ObservableObject {
    static let shared = FavoriteService()
    static let favoritesChangedNotification = Notification.Name("AIDreamFavoritesChanged")

    private let storageKey = "com.aidream.favorites"

    @Published var favoriteIds: Set<Int> = []
    @Published var favoriteVideos: [VideoData] = []

    private init() {
        loadFavorites()
    }

    func isFavorited(_ videoId: Int) -> Bool {
        return favoriteIds.contains(videoId)
    }

    func toggleFavorite(_ video: VideoData) {
        if self.favoriteIds.contains(video.id) {
            self.favoriteIds.remove(video.id)
            self.favoriteVideos.removeAll { $0.id == video.id }
        } else {
            self.favoriteIds.insert(video.id)
            self.favoriteVideos.insert(video, at: 0) // Newest first
        }
        self.saveFavorites()

        // 发送全局通知，确保各处 UI 同步更新状态
        NotificationCenter.default.post(
            name: Self.favoritesChangedNotification,
            object: nil,
            userInfo: ["videoId": video.id]
        )
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteVideos) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([VideoData].self, from: data) {
            self.favoriteVideos = decoded
            self.favoriteIds = Set(decoded.map { $0.id })
        }
    }
}
