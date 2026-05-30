import Foundation
import CoreGraphics

struct HFResponse: Decodable {
    let rows: [HFRow]
}

struct HFRow: Decodable {
    let row: VideoData
}

struct VideoData: Decodable, Identifiable {
    let workId: Int
    let workItemId: Int?
    let taskId: Int?
    let userId: Int?
    let type: String
    let status: Int
    let contentType: String
    let resource: MediaResource
    let cover: MediaResource?
    let starNum: Int?
    let reportNum: Int?
    let createTime: Int64
    let taskInfo: TaskInfo
    let selfAttitude: String?
    let selfComment: SelfComment?
    let favored: Bool?
    let starred: Bool?
    let publishStatus: String?
    let deleted: Bool
    let title: String?
    let userProfile: UserProfile?
    let publishTime: Int64?
    let submitTime: Int64?
    let lipSyncStatus: Int?
    let introduction: String?

    var id: Int {
        workId
    }

    var category: String {
        type
    }

    var prompt: String {
        taskInfo.prompt ?? introduction ?? title ?? ""
    }

    var displayTitle: String {
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedPrompt.isEmpty ? "未命名视频" : trimmedPrompt
    }

    var secondaryText: String {
        let intro = introduction?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !intro.isEmpty, intro != displayTitle {
            return intro
        }

        let promptText = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !promptText.isEmpty, promptText != displayTitle {
            return promptText
        }

        return ""
    }

    var durationText: String {
        let seconds = max(resource.duration / 1000, 0)
        return seconds > 0 ? "\(seconds)s" : ""
    }

    var playCountText: String {
        Self.formatCount(starNum ?? 0) + " plays"
    }

    var aspectRatio: CGFloat {
        let width = CGFloat(max(resource.width, 1))
        let height = CGFloat(max(resource.height, 1))
        return width / height
    }

    var videoURL: URL? {
        URL(string: resource.resource)
    }

    var coverURL: URL? {
        guard let cover else { return nil }
        return URL(string: cover.resource)
    }

    var isPlayable: Bool {
        !deleted && contentType.lowercased() == "video" && videoURL != nil
    }

    enum CodingKeys: String, CodingKey {
        case workId
        case workItemId
        case taskId
        case userId
        case type
        case status
        case contentType
        case resource
        case cover
        case starNum
        case reportNum
        case createTime
        case taskInfo
        case selfAttitude
        case selfComment
        case favored
        case starred
        case publishStatus
        case deleted
        case title
        case userProfile
        case publishTime
        case submitTime
        case lipSyncStatus
        case introduction
    }

    private static func formatCount(_ count: Int) -> String {
        switch count {
        case 1_000_000...:
            let value = Double(count) / 1_000_000
            return formatDecimal(value) + "M"
        case 1_000...:
            let value = Double(count) / 1_000
            return formatDecimal(value) + "k"
        default:
            return "\(count)"
        }
    }

    private static func formatDecimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.rounded(.down) == rounded {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }
}

struct MediaResource: Decodable {
    let resource: String
    let height: Int
    let width: Int
    let duration: Int
}

struct TaskInfo: Decodable {
    let type: String?
    let inputs: [TaskInput]
    let arguments: [TaskArgument]
    let extraArgs: TaskExtraArgs?

    init(type: String? = nil, inputs: [TaskInput] = [], arguments: [TaskArgument] = [], extraArgs: TaskExtraArgs? = nil) {
        self.type = type
        self.inputs = inputs
        self.arguments = arguments
        self.extraArgs = extraArgs
    }

    var prompt: String? {
        arguments.first(where: { $0.name == "prompt" })?.value
    }

    enum CodingKeys: String, CodingKey {
        case type
        case inputs
        case arguments
        case extraArgs
    }
}

struct TaskInput: Decodable {
    let name: String?
    let inputType: String?
    let token: String?
    let blobStorage: String?
    let url: String?
    let fromWorkId: Int64?
}

struct TaskArgument: Decodable {
    let name: String
    let value: String
}

struct TaskExtraArgs: Decodable {
    let refererWorkId: String?
}

struct SelfComment: Decodable {
    let tags: [String]
    let content: String
    let prompts: [String?]
}

struct UserProfile: Decodable {
    let userId: Int
    let userName: String
    let userAvatar: [String]
    let introduction: String
    let features: [UserFeature]
    let enableConsole: Bool
    let enableInvoiceTitleCollection: Bool
    let kol: Bool
}

struct UserFeature: Decodable {
    let name: String
    let allowed: Bool
}
