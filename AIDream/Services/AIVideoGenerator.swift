import SwiftUI
import UIKit
import Combine

// MARK: - 视频生成状态
@MainActor
class AIVideoGenerator: ObservableObject {

    enum VideoGenerationState: Equatable {
        case idle
        case uploading                   // 准备请求
        case generating(Double)          // 生成中（轮询进度 0~1）
        case completed(URL)              // 完成，返回视频 URL
        case failed(String)

        var description: String {
            switch self {
            case .idle:               return "Ready"
            case .uploading:          return "Submitting job…"
            case .generating(let p):  return "Generating… \(Int(p * 100))%"
            case .completed:          return "Video Ready"
            case .failed(let e):      return "Error: \(e)"
            }
        }
    }

    // MARK: - Properties
    @Published var state: VideoGenerationState = .idle

    static let shared = AIVideoGenerator()
    private init() {}

    private var pollingTask: Task<Void, Never>?

    // MARK: - Public API

    /// 生成视频（Image to Video 或 Text to Video）
    /// - Parameters:
    ///   - prompt:    描述文字
    ///   - image:     起始帧图片（可选，传 nil 则走 Text-to-Video）
    ///   - duration:  "6s" 或 "10s"（Hailuo 2.3 仅支持这两个值）
    ///   - quality:   "Standard" / "High" / "Ultra HD"（映射到分辨率）
    ///   - ratio:     "9:16" / "1:1"
    func generateVideo(
        prompt: String,
        image: UIImage?,
        endImage: UIImage? = nil,
        duration: String,
        quality: String,
        ratio: String
    ) {
        pollingTask?.cancel()
        pollingTask = Task {
            state = .uploading

            do {
                let pollingURL = try await submitJob(
                    prompt: prompt,
                    image: image,
                    endImage: endImage,
                    duration: duration,
                    quality: quality,
                    ratio: ratio
                )
                state = .generating(0.1)
                let videoURL = try await pollUntilDone(pollingURL: pollingURL)
                state = .completed(videoURL)
            } catch is CancellationError {
                // 用户主动取消，不报错
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func cancelGeneration() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }

    // MARK: - Step 1: 提交任务 → 返回 job id

    private func submitJob(
        prompt: String,
        image: UIImage?,
        endImage: UIImage?,
        duration: String,
        quality: String,
        ratio: String
    ) async throws -> URL {

        let apiKey = AIConfig.shared.openRouterApiKey
        guard !apiKey.isEmpty else { throw VideoError.missingApiKey }

        guard let baseURL = URL(string: AIConfig.shared.openRouterBaseURL),
              let url = URL(string: "videos", relativeTo: baseURL) else {
            throw VideoError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)",   forHTTPHeaderField: "Authorization")
        request.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        request.setValue("AIDream",             forHTTPHeaderField: "X-Title")

        // 构建请求体
        var body: [String: Any] = [
            "model":        AIConfig.shared.openRouterVideoModel,
            "prompt":       prompt,
            "duration":     durationSeconds(from: duration),   // Int: 6 或 10
            "aspect_ratio": ratio,                             // "9:16" / "1:1"
            "resolution":   resolution(from: quality)         // "720p" / "1080p"
        ]

        // 图片 → 首帧 / 尾帧（Image to Video）
        var frameImages: [[String: Any]] = []
        if let firstFrame = frameImagePayload(image: image, frameType: "first_frame") {
            frameImages.append(firstFrame)
        }
        if let lastFrame = frameImagePayload(image: endImage, frameType: "last_frame") {
            frameImages.append(lastFrame)
        }
        if !frameImages.isEmpty {
            body["frame_images"] = frameImages
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw VideoError.invalidResponse
        }

        // OpenRouter 视频 API 提交成功返回 202 Accepted
        guard http.statusCode == 202 || http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw VideoError.serverError("HTTP \(http.statusCode): \(msg)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VideoError.invalidResponse
        }

        if let pollingURLString = json["polling_url"] as? String,
           let pollingURL = URL(string: pollingURLString, relativeTo: baseURL)?.absoluteURL {
            return pollingURL
        }

        if let jobID = json["id"] as? String,
           let fallbackURL = URL(string: "videos/\(jobID)", relativeTo: baseURL)?.absoluteURL {
            return fallbackURL
        }

        throw VideoError.invalidResponse
    }

    // MARK: - Step 2: 轮询直到完成

    private func pollUntilDone(pollingURL url: URL) async throws -> URL {
        let apiKey = AIConfig.shared.openRouterApiKey

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 最多轮询 60 次 × 5 秒间隔 = 5 分钟
        for attempt in 1...60 {
            try Task.checkCancellation()

            // 每次等 5 秒再查询（首次也稍等）
            try await Task.sleep(nanoseconds: 5_000_000_000)
            try Task.checkCancellation()

            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw VideoError.invalidResponse
            }

            let status = json["status"] as? String ?? "pending"

            // 更新进度（模拟 0.1 → 0.95）
            let progress = min(0.1 + Double(attempt) * 0.015, 0.95)
            state = .generating(progress)

            switch status {
            case "completed":
                if let urls = json["unsigned_urls"] as? [String],
                   let first = urls.first,
                   let videoURL = URL(string: first) {
                    return videoURL
                }
                throw VideoError.urlNotFound

            case "failed", "cancelled", "expired":
                let msg = json["error"] as? String ?? status
                throw VideoError.serverError(msg)

            default:
                // pending / in_progress → 继续等待
                continue
            }
        }

        throw VideoError.timeout
    }

    // MARK: - 参数映射

    /// Hailuo 2.3 支持 6 或 10 秒；"5s" 向上取整为 6
    private func durationSeconds(from duration: String) -> Int {
        let s = Int(duration.replacingOccurrences(of: "s", with: "")) ?? 6
        return s <= 6 ? 6 : 10
    }

    /// 质量 → 分辨率
    private func resolution(from quality: String) -> String {
        switch quality {
        case "High":     return "1080p"
        case "Ultra HD": return "1080p"   // Hailuo 2.3 最高支持 1080p
        default:         return "720p"
        }
    }

    private func frameImagePayload(image: UIImage?, frameType: String) -> [String: Any]? {
        guard let image,
              let jpegData = image.jpegData(compressionQuality: 0.85) else {
            return nil
        }

        return [
            "type": "image_url",
            "frame_type": frameType,
            "image_url": [
                "url": "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
            ]
        ]
    }

    // MARK: - 错误类型

    enum VideoError: LocalizedError {
        case missingApiKey
        case invalidURL
        case serverError(String)
        case invalidResponse
        case urlNotFound
        case timeout

        var errorDescription: String? {
            switch self {
            case .missingApiKey:       return "OpenRouter API Key 未配置"
            case .invalidURL:          return "无效的接口地址"
            case .serverError(let s):  return "服务器错误：\(s)"
            case .invalidResponse:     return "响应格式异常"
            case .urlNotFound:         return "未获取到视频 URL"
            case .timeout:             return "生成超时（>5 分钟），请重试"
            }
        }
    }
}
