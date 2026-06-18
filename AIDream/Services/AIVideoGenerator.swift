import SwiftUI
import UIKit
import Combine
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "VideoGen")

// MARK: - 视频生成服务
@MainActor
class AIVideoGenerator: ObservableObject {

    enum VideoGenerationState: Equatable {
        case idle
        case uploading
        case generating(Double)
        case completed(URL)
        case failed(String)

        var description: String {
            switch self {
            case .idle:               return "Ready"
            case .uploading:          return "Connecting to AI..."
            case .generating(let p):  return "Generating... \(Int(p * 100))%"
            case .completed(_):       return "Video Ready"
            case .failed(let e):      return "Error: \(e)"
            }
        }
    }

    @Published var state: VideoGenerationState = .idle
    static let shared = AIVideoGenerator()
    private init() {}

    private var pollingTask: Task<Void, Never>?

    func generateVideo(
        prompt: String,
        image: UIImage?,
        endImage: UIImage? = nil,
        duration: String,
        quality: String,
        ratio: String
    ) {
        logger.info("Starting generation via OpenRouter Dedicated Video API")

        pollingTask?.cancel()
        pollingTask = Task {
            state = .uploading
            do {
                // 1. 提交专属异步视频任务
                let jobId = try await submitVideoJob(
                    prompt: prompt,
                    image: image,
                    endImage: endImage,
                    duration: duration,
                    ratio: ratio,
                    quality: quality
                )

                state = .generating(0.05)
                
                // 2. 轮询专属媒体任务状态
                let videoURL = try await pollVideoJob(jobId: jobId)
                state = .completed(videoURL)
                
            } catch is CancellationError {
                state = .idle
            } catch {
                logger.error("Final Failure: \(error.localizedDescription)")
                state = .failed(error.localizedDescription)
            }
        }
    }

    func cancelGeneration() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }

    // MARK: - 1. 提交专属视频任务 (POST /api/v1/videos)
    private func submitVideoJob(
        prompt: String,
        image: UIImage?,
        endImage: UIImage?,
        duration: String,
        ratio: String,
        quality: String
    ) async throws -> String {

        let apiKey = AIConfig.shared.openRouterApiKey
        guard !apiKey.isEmpty else { throw VideoError.missingApiKey }

        let url = URL(string: "https://openrouter.ai/api/v1/videos")!

        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://aidream.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("AIDream", forHTTPHeaderField: "X-Title")

        // 构造标准的多模态视频 Body 骨架
        var body: [String: Any] = [
            "model": AIConfig.shared.openRouterVideoModel,
            "prompt": prompt.isEmpty ? "A cinematic video with high quality motion" : prompt,
            "aspect_ratio": ratio
        ]

        // 时长
        let durationVal = Int(duration.replacingOccurrences(of: "s", with: "")) ?? 5
        body["duration"] = durationVal

        // 品质映射
        switch quality {
        case "Ultra HD": body["quality"] = "ultra_hd"
        case "High":     body["quality"] = "high"
        default:         body["quality"] = "standard"
        }

        // 🟢 完美对齐 OpenRouter Zod 严格断言的嵌套图片数组
        var frameImages: [[String: Any]] = []

        // 处理起始帧 (first_frame)
        if let img = image, let b64 = processAndEncodeImage(img, maxDim: 720) {
            frameImages.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(b64)"
                ],
                "frame_type": "first_frame"
            ])
        }

        // 处理结束帧 (last_frame)
        if let endImg = endImage, let b64End = processAndEncodeImage(endImg, maxDim: 720) {
            frameImages.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(b64End)"
                ],
                "frame_type": "last_frame"
            ])
        }

        if !frameImages.isEmpty {
            body["frame_images"] = frameImages
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData

        logger.debug("Request Payload Size: \(bodyData.count / 1024) KB")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw VideoError.invalidResponse }

        if http.statusCode >= 400 {
            let rawBody = String(data: data, encoding: .utf8) ?? "No body"
            logger.error("HTTP \(http.statusCode) Error Response: \(rawBody)")
            throw VideoError.serverError("HTTP \(http.statusCode): \(rawBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VideoError.invalidResponse
        }

        // 解析下发的异步生成 Job ID
        guard let jobId = json["id"] as? String ?? (json["data"] as? [String: Any])?["id"] as? String else {
            throw VideoError.serverError("Accepted, but no video job ID returned.")
        }

        logger.info("Job Created Successfully. ID: \(jobId)")
        return jobId
    }

    // MARK: - 2. 轮询专属视频状态 (GET /api/v1/videos/{id})
    private func pollVideoJob(jobId: String) async throws -> URL {
        let apiKey = AIConfig.shared.openRouterApiKey
        let url = URL(string: "https://openrouter.ai/api/v1/videos/\(jobId)")!
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 视频生成通常 15-120 秒，最多轮询 60 次 × 5 秒 = 5 分钟
        let maxPollAttempts = 60
        for attempt in 1...maxPollAttempts {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 5_000_000_000) // 间隔 5 秒
            try Task.checkCancellation()

            logger.debug("Polling attempt \(attempt)/\(maxPollAttempts)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { continue }

            let jobInfo = json["data"] as? [String: Any] ?? json
            let status = (jobInfo["status"] as? String)?.lowercased() ?? "pending"
            logger.debug("Current Status: \(status)")

            state = .generating(min(0.05 + Double(attempt) / Double(maxPollAttempts) * 0.94, 0.99))

            switch status {
            case "completed", "succeeded", "success":
                // 兼容解析不同的结果承载字段
                let urlStr = (jobInfo["unsigned_urls"] as? [String])?.first ??
                             (jobInfo["results"] as? [[String: Any]])?.first?["url"] as? String ??
                             (jobInfo["url"] as? String)
                
                if let urlStr = urlStr, let finalURL = URL(string: urlStr) {
                    return finalURL
                }
                throw VideoError.urlNotFound

            case "failed", "error", "cancelled", "expired":
                let msg = jobInfo["error"] as? String ?? (jobInfo["data"] as? [String: Any])?["error"] as? String ?? "Generation failed"
                throw VideoError.serverError(msg)

            default:
                continue
            }
        }
        throw VideoError.timeout
    }

    // MARK: - 辅助：高质量图片缩放编码
    private func processAndEncodeImage(_ image: UIImage, maxDim: CGFloat) -> String? {
        let size = image.size
        let ratio = min(maxDim / size.width, maxDim / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized?.jpegData(compressionQuality: 0.5)?.base64EncodedString()
    }

    enum VideoError: LocalizedError {
        case missingApiKey, invalidURL, serverError(String), invalidResponse, urlNotFound, timeout
        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "API Key Missing"
            case .serverError(let s): return "Server: \(s)"
            case .timeout: return "Timeout"
            default: return "Video creation failed."
            }
        }
    }
}
