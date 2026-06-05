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
        // Ensure updates happen on the main thread for SwiftUI observers
        DispatchQueue.main.async {
            if self.favoriteIds.contains(video.id) {
                self.favoriteIds.remove(video.id)
                self.favoriteVideos.removeAll { $0.id == video.id }
            } else {
                self.favoriteIds.insert(video.id)
                self.favoriteVideos.insert(video, at: 0) // Newest first
            }
            self.saveFavorites()

            // Notify UIKit components or other observers
            NotificationCenter.default.post(
                name: Self.favoritesChangedNotification,
                object: nil,
                userInfo: ["videoId": video.id]
            )
        }
    }

    private func saveFavorites() {
        do {
            let encoded = try JSONEncoder().encode(favoriteVideos)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            UserDefaults.standard.synchronize() // Force save for reliability
        } catch {
            print("Error saving favorites: \(error)")
        }
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([VideoData].self, from: data)
            self.favoriteVideos = decoded
            self.favoriteIds = Set(decoded.map { $0.id })
        } catch {
            print("Error loading favorites: \(error)")
            // If data is corrupted or model changed, consider clearing it
            // UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
}
