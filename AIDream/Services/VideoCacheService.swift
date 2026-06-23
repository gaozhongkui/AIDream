import Foundation
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "Cache")

class VideoCacheService {
    static let shared = VideoCacheService()
    private let cacheKey = "cached_videos"
    private let fileURL: URL
    private let videoCacheDirectory: URL

    init() {
        let manager = FileManager.default
        let urls = manager.urls(for: .documentDirectory, in: .userDomainMask)
        fileURL = urls[0].appendingPathComponent("videos.json")

        // 创建专门存储视频文件的目录
        let cachesURL = manager.urls(for: .cachesDirectory, in: .userDomainMask)
        videoCacheDirectory = cachesURL[0].appendingPathComponent("VideoCache", isDirectory: true)

        if !manager.fileExists(atPath: videoCacheDirectory.path) {
            try? manager.createDirectory(at: videoCacheDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Metadata Cache
    func saveVideos(_ videos: [VideoData]) {
        do {
            let data = try JSONEncoder().encode(videos)
            try data.write(to: fileURL)
        } catch {
            logger.error("Failed to save videos to cache: \(error)")
        }
    }

    func loadVideos() -> [VideoData] {
        do {
            let data = try Data(contentsOf: fileURL)
            let videos = try JSONDecoder().decode([VideoData].self, from: data)
            return videos
        } catch {
            return []
        }
    }

    // MARK: - Video File Cache & Preload

    /// 获取视频的本地缓存路径（如果存在）
    func cachedLocation(for remoteURL: URL) -> URL? {
        let fileName = remoteURL.lastPathComponent
        let localURL = videoCacheDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }

    /// 预加载视频到本地
    func preloadVideo(url: URL) {
        let fileName = url.lastPathComponent
        let localURL = videoCacheDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localURL.path) { return }

        URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else { return }
            try? FileManager.default.moveItem(at: tempURL, to: localURL)
            logger.info("Preloaded video successfully: \(fileName)")
        }.resume()
    }
}
