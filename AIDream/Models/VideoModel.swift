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
    let category: String?

    static let all = VideoFilterOption(id: "all", title: "全部", category: nil)

    static func options(from videos: [VideoData]) -> [VideoFilterOption] {
        var seen = Set<String>()
        let uniqueCategories = videos.compactMap { video -> String? in
            let cat = video.category.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cat.isEmpty, seen.insert(cat).inserted else { return nil }
            return cat
        }

        return [.all] + uniqueCategories.sorted().map { cat in
            VideoFilterOption(id: cat, title: VideoData.displayCategory(cat), category: cat)
        }
    }
}

struct VideoData: Decodable, Identifiable {
    let prompt: String
    let video: String
    let category: String
    let videoName: String

    var id: String { videoName }

    var videoURL: URL? {
        URL(string: video.replacingOccurrences(of: ".gif", with: ".mp4"))
    }

    var coverURL: URL? {
        URL(string: video)
    }

    var displayTitle: String { prompt }

    var secondaryText: String { "" }

    var durationText: String { "" }

    var aspectRatio: CGFloat { 3.0 / 4.0 }

    static func displayCategory(_ category: String) -> String {
        return category
    }

    enum CodingKeys: String, CodingKey {
        case prompt = "Prompt"
        case video = "Video"
        case category = "Category"
        case videoName = "video_name"
    }
}
