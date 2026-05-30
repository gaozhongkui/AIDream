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

    func toVideoData() -> VideoData {
        return VideoData(
            id: workId,
            title: title ?? "Untitled",
            introduction: introduction ?? "",
            videoURL: URL(string: resource.resource),
            coverURL: URL(string: cover.resource),
            userName: userProfile.userName,
            userAvatarURL: URL(string: userProfile.userAvatar?.first ?? ""),
            starCount: starNum,
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
