import Foundation

// MARK: - UI Model
struct VideoData: Identifiable, Codable {
    let id: Int
    let title: String
    let introduction: String
    let videoURL: URL?
    let coverURL: URL?
    let userName: String
    let userAvatarURL: URL?
    let starCount: Int
    let width: Int
    let height: Int

    var aspectRatio: Double {
        return Double(height) / Double(width)
    }
}

// MARK: - API Response Models (Hugging Face / Kling AI)
struct HFResponse: Codable {
    let rows: [HFRow]
}

struct HFRow: Codable {
    let row: VideoItem
}

struct VideoItem: Codable {
    let workId: Int
    let title: String?
    let introduction: String?
    let starNum: Int
    let resource: VideoResource
    let cover: VideoResource
    let userProfile: UserProfile

    /// 缓存已随机过的 starCount，确保同一 workId 不会被重复随机。
    private static var starCountCache: [Int: Int] = [:]

    func toVideoData() -> VideoData {
        let star: Int
        if starNum >= 1000 {
            star = starNum
        } else if let cached = Self.starCountCache[workId] {
            star = cached
        } else {
            let random = Int.random(in: 1000...9999)
            Self.starCountCache[workId] = random
            star = random
        }

        return VideoData(
            id: workId,
            title: title ?? NSLocalizedString("label_untitled", comment: ""),
            introduction: introduction ?? "",
            videoURL: URL(string: resource.resource),
            coverURL: URL(string: cover.resource),
            userName: userProfile.userName,
            userAvatarURL: URL(string: userProfile.userAvatar?.first ?? ""),
            starCount: star,
            width: cover.width,
            height: cover.height
        )
    }
}

struct VideoResource: Codable {
    let resource: String
    let height: Int
    let width: Int
    let duration: Int
}

struct UserProfile: Codable {
    let userId: Int
    let userName: String
    let userAvatar: [String]?
    let introduction: String?
}
