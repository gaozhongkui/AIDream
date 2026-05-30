import Foundation

class VideoCacheService {
    static let shared = VideoCacheService()
    private let cacheKey = "cached_videos"
    private let fileURL: URL

    init() {
        let manager = FileManager.default
        let urls = manager.urls(for: .documentDirectory, in: .userDomainMask)
        fileURL = urls[0].appendingPathComponent("videos.json")
    }

    func saveVideos(_ videos: [VideoData]) {
        do {
            let data = try JSONEncoder().encode(videos)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save videos to cache: \(error)")
        }
    }

    func loadVideos() -> [VideoData] {
        do {
            let data = try Data(contentsOf: fileURL)
            let videos = try JSONDecoder().decode([VideoData].self, from: data)
            return videos
        } catch {
            print("Failed to load videos from cache: \(error)")
            return []
        }
    }
}
