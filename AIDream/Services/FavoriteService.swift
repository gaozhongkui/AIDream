import Foundation
import Combine

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
        if favoriteIds.contains(video.id) {
            favoriteIds.remove(video.id)
            favoriteVideos.removeAll { $0.id == video.id }
        } else {
            favoriteIds.insert(video.id)
            favoriteVideos.insert(video, at: 0) // Newest first
        }
        saveFavorites()

        // 发送全局通知，确保各处 UI 同步更新状态
        NotificationCenter.default.post(name: Self.favoritesChangedNotification, object: nil, userInfo: ["videoId": video.id])
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
