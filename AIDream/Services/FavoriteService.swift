import Foundation
import Combine
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "Favorite")

/// 管理收藏夹服务的单例。
/// 使用 @MainActor 确保所有状态更新都在主线程进行，解决 UI 同步和测试竞争问题。
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
        if favoriteIds.contains(video.id) {
            favoriteIds.remove(video.id)
            favoriteVideos.removeAll { $0.id == video.id }
        } else {
            favoriteIds.insert(video.id)
            favoriteVideos.insert(video, at: 0) // 新收藏的排在最前面
        }
        saveFavorites()

        // 发送全局通知，主要用于 UIKit 组件监听（如 VideoCell）
        NotificationCenter.default.post(
            name: Self.favoritesChangedNotification,
            object: nil,
            userInfo: ["videoId": video.id]
        )
    }

    private func saveFavorites() {
        do {
            let encoded = try JSONEncoder().encode(favoriteVideos)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            // 显式调用以确保即时保存，尽管现代系统会自动处理
            UserDefaults.standard.synchronize()
        } catch {
            logger.error("Error saving favorites: \(error)")
        }
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([VideoData].self, from: data)
            self.favoriteVideos = decoded
            self.favoriteIds = Set(decoded.map { $0.id })
        } catch {
            logger.error("Error loading favorites: \(error)")
        }
    }
}
