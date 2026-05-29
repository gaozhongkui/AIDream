import Foundation
import CoreGraphics

struct HFResponse: Decodable {
    let rows: [HFRow]
}

struct HFRow: Decodable {
    let row: VideoData
}

struct VideoFilterOption: Identifiable, Equatable {
    let id: String
    let title: String
    let type: String?

    static let all = VideoFilterOption(id: "all", title: "全部", type: nil)

    static func options(from videos: [VideoData]) -> [VideoFilterOption] {
        var seenTypes = Set<String>()
        let uniqueTypes = videos.compactMap { video -> String? in
            let type = video.type.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !type.isEmpty, seenTypes.insert(type).inserted else { return nil }
            return type
        }

        let sortedTypes = uniqueTypes.sorted { lhs, rhs in
            VideoData.filterTitle(for: lhs) < VideoData.filterTitle(for: rhs)
        }

        return [.all] + sortedTypes.map { type in
            VideoFilterOption(id: type, title: VideoData.filterTitle(for: type), type: type)
        }
    }
}

struct VideoData: Decodable, Identifiable {
    let workId: Int
    let type: String
    let status: Int
    let contentType: String
    let resource: MediaResource
    let cover: MediaResource?
    let starNum: Int?
    let reportNum: Int?
    let createTime: Int64
    let taskInfo: TaskInfo
    let publishStatus: String?
    let deleted: Bool
    let title: String
    let introduction: String?
    let publishTime: Int64?
    let submitTime: Int64?

    var id: Int {
        workId
    }

    var videoURL: URL? {
        URL(string: resource.resource)
    }

    var coverURL: URL? {
        guard let coverURLString = cover?.resource else { return nil }
        return URL(string: coverURLString)
    }

    var displayTitle: String {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return promptText
        }
        return title
    }

    var promptText: String {
        if let prompt = taskInfo.prompt, !prompt.isEmpty {
            return prompt
        }
        if let introduction, !introduction.isEmpty {
            return introduction
        }
        return title
    }

    var secondaryText: String {
        let candidate = introduction?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !candidate.isEmpty, candidate != displayTitle {
            return candidate
        }
        let prompt = taskInfo.prompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !prompt.isEmpty, prompt != displayTitle {
            return prompt
        }
        return ""
    }

    var durationText: String {
        let seconds = max(resource.duration / 1000, 0)
        return seconds > 0 ? "\(seconds)s" : ""
    }

    var aspectRatio: CGFloat {
        let width = CGFloat(max(resource.width, 1))
        let height = CGFloat(max(resource.height, 1))
        return width / height
    }

    var isPlayable: Bool {
        !deleted && contentType.lowercased() == "video" && videoURL != nil
    }

    static func filterTitle(for type: String) -> String {
        let normalizedType = type.lowercased()
        if normalizedType.contains("txt2video") || normalizedType.contains("text2video") {
            return "文生视频"
        }
        if normalizedType.contains("img2video") || normalizedType.contains("image2video") {
            return "图生视频"
        }

        let pieces = type
            .replacingOccurrences(of: "-", with: "_")
            .split(separator: "_")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if pieces.isEmpty {
            return type
        }

        return pieces
            .map { part in
                if part.allSatisfy({ $0.isNumber }) {
                    return part
                }
                return part.prefix(1).uppercased() + part.dropFirst().lowercased()
            }
            .joined(separator: " ")
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
    let arguments: [TaskArgument]

    init(type: String? = nil, arguments: [TaskArgument] = []) {
        self.type = type
        self.arguments = arguments
    }

    var prompt: String? {
        arguments.first(where: { $0.name == "prompt" })?.value
    }

    enum CodingKeys: String, CodingKey {
        case type
        case arguments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        arguments = try container.decodeIfPresent([TaskArgument].self, forKey: .arguments) ?? []
    }
}

struct TaskArgument: Decodable {
    let name: String
    let value: String
}
