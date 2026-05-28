import Foundation

struct HFResponse: Codable {
    let rows: [HFRow]
}

struct HFRow: Codable {
    let row: VideoData
}

struct VideoData: Codable {
    let video: String
    let prompt: String

    // 这里的接口返回可能包含多个字段，根据 awesome-text2video-prompts 的典型结构定义
    // 如果 video 字段是相对路径，可能需要拼接前缀，但通常 rows 接口会返回完整的 URL 或可下载的对象
}
