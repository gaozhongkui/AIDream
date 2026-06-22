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
            case .idle:               return "Ready to Create"
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
        logger.info("Starting video generation process")

        pollingTask?.cancel()
        pollingTask = Task {
            state = .uploading
            do {
                // --- 方案 A: 尝试 Hugging Face ---
                do {
                    logger.info("Attempting Hugging Face generation...")
                    let videoURL = try await generateWithHuggingFace(prompt: prompt, image: image)
                    state = .completed(videoURL)
                    logger.info("Hugging Face generation successful!")
                    return // 成功则直接返回
                } catch {
                    logger.warning("Hugging Face failed: \(error.localizedDescription). Falling back to OpenRouter...")
                }

                // --- 方案 B: 回退到 OpenRouter ---
                state = .uploading // 重置状态
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

                // 验证 URL 合法性
                guard videoURL.scheme == "https" || videoURL.isFileURL else {
                    logger.error("Security Risk: AI returned an invalid URL: \(videoURL.absoluteString)")
                    throw VideoError.serverError("Insecure video source.")
                }

                state = .completed(videoURL)
                logger.info("OpenRouter fallback successful: \(videoURL.absoluteString)")

            } catch is CancellationError {
                logger.info("Generation task was cancelled.")
                state = .idle
            } catch let error as VideoError {
                logger.error("Video Generation Error: \(error.localizedDescription)")
                state = .failed(error.localizedDescription)
            } catch {
                logger.error("Unknown Failure: \(error.localizedDescription)")
                state = .failed("An unexpected error occurred.")
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

        // 使用 AIConfig 中的 BaseURL
        let url = URL(string: "\(AIConfig.shared.openRouterBaseURL)/videos")!

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

        // 时长转换
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
        if let img = image, let b64 = processAndEncodeImage(img, maxDim: 1024) { // 稍微提升分辨率到 1024
            frameImages.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(b64)"
                ],
                "frame_type": "first_frame"
            ])
        }

        // 处理结束帧 (last_frame)
        if let endImg = endImage, let b64End = processAndEncodeImage(endImg, maxDim: 1024) {
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

        if http.statusCode == 401 {
            throw VideoError.serverError("Invalid API Key. Please check your settings.")
        } else if http.statusCode == 402 {
            throw VideoError.serverError("Insufficient credits on OpenRouter.")
        } else if http.statusCode >= 400 {
            let rawBody = String(data: data, encoding: .utf8) ?? "Unknown Error"
            logger.error("HTTP \(http.statusCode) Error Response: \(rawBody)")
            throw VideoError.serverError("Service Error (\(http.statusCode))")
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
        // 使用 AIConfig 中的 BaseURL
        let url = URL(string: "\(AIConfig.shared.openRouterBaseURL)/videos/\(jobId)")!
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 视频生成通常 15-120 秒，最多轮询 100 次 × 3 秒 = 5 分钟 (缩短间隔提高响应度)
        let maxPollAttempts = 100
        let pollInterval: UInt64 = 3_000_000_000

        for attempt in 1...maxPollAttempts {
            try Task.checkCancellation()

            // 第一次轮询前也等待，给服务器处理时间
            try await Task.sleep(nanoseconds: pollInterval)
            try Task.checkCancellation()

            logger.debug("Polling attempt \(attempt)/\(maxPollAttempts)")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    logger.warning("Polling error: Invalid response code")
                    continue
                }

                guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                    continue
                }

                let jobInfo = json["data"] as? [String: Any] ?? json
                let status = (jobInfo["status"] as? String)?.lowercased() ?? "pending"
                logger.debug("Current Status: \(status)")

                // 进度反馈：前 80% 随时间增加，最后 20% 等待完成
                let progress = min(0.1 + (Double(attempt) / Double(maxPollAttempts) * 0.8), 0.95)
                state = .generating(progress)

                switch status {
                case "completed", "succeeded", "success":
                    let urlStr = (jobInfo["unsigned_urls"] as? [String])?.first ??
                                 (jobInfo["results"] as? [[String: Any]])?.first?["url"] as? String ??
                                 (jobInfo["url"] as? String)

                    if let urlStr = urlStr, let finalURL = URL(string: urlStr) {
                        return finalURL
                    }
                    throw VideoError.urlNotFound

                case "failed", "error", "cancelled", "expired":
                    let msg = jobInfo["error"] as? String ??
                              (jobInfo["data"] as? [String: Any])?["error"] as? String ??
                              "Generation failed"
                    throw VideoError.serverError(msg)

                default:
                    continue
                }
            } catch let error as VideoError {
                throw error
            } catch {
                logger.warning("Polling request failed: \(error.localizedDescription). Retrying...")
                continue // 网络波动则重试
            }
        }
        throw VideoError.timeout
    }

    // MARK: - 3. Hugging Face 视频生成 (方案 A)
    private func generateWithHuggingFace(prompt: String, image: UIImage?) async throws -> URL {
        let model = AIConfig.shared.huggingFaceVideoModel
        let token = AIConfig.shared.huggingFaceToken

        // 如果没有配置 Token 且不是公开端点，抛出错误以触发回退
        guard !token.isEmpty, token != "hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" else {
            throw VideoError.missingApiKey
        }

        let endpoint = "\(AIConfig.shared.huggingFaceBaseURL)/\(model)"
        guard let url = URL(string: endpoint) else { throw VideoError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 缩短连接超时，以便快速回退到 OpenRouter

        // 构造输入，SVD 等模型通常需要图片输入
        var payload: [String: Any] = ["inputs": prompt]
        if let img = image, let b64 = processAndEncodeImage(img, maxDim: 1024) {
            payload["image"] = "data:image/jpeg;base64,\(b64)"
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw VideoError.invalidResponse }

        // 处理 HF 的 503 (模型加载中) 或其他错误
        if http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            logger.warning("HF API Error: \(msg)")
            throw VideoError.serverError("HF API Error: \(http.statusCode)")
        }

        // 很多 HF 视频接口直接返回视频二进制流，将其存入临时文件
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        try data.write(to: tempURL)
        return tempURL
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
        
        return resized?.jpegData(compressionQuality: 0.7)?.base64EncodedString() // 提升压缩质量到 0.7
    }

    enum VideoError: LocalizedError {
        case missingApiKey, invalidURL, serverError(String), invalidResponse, urlNotFound, timeout
        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "API Key Missing"
            case .serverError(let s): return s
            case .timeout: return "Generation took too long. Please check back later."
            case .urlNotFound: return "Video generated but link was not found."
            default: return "Video creation failed."
            }
        }
    }
}
