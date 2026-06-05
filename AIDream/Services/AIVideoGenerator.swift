import SwiftUI
import UIKit
import Combine

// MARK: - 视频生成状态
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
            case .uploading:          return "Submitting job…"
            case .generating(let p):  return "Generating… \(Int(p * 100))%"
            case .completed:          return "Video Ready"
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
        let finalPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "A cinematic video with high quality motion" : prompt
        print("🚀 [VideoGen] Start (Model: \(AIConfig.shared.openRouterVideoModel))")

        pollingTask?.cancel()
        pollingTask = Task {
            state = .uploading
            do {
                let result = try await submitJob(
                    prompt: finalPrompt,
                    image: image,
                    endImage: endImage,
                    duration: duration,
                    quality: quality,
                    ratio: ratio
                )

                switch result {
                case .completed(let url):
                    state = .completed(url)
                case .polling(let pollingURL):
                    state = .generating(0.05)
                    let videoURL = try await pollUntilDone(pollingURL: pollingURL)
                    state = .completed(videoURL)
                }
            } catch is CancellationError {
                state = .idle
            } catch {
                let msg = error.localizedDescription
                print("❌ [VideoGen] Final Failure: \(msg)")
                state = .failed(msg)
            }
        }
    }

    func cancelGeneration() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }

    private enum SubmitResult {
        case completed(URL)
        case polling(URL)
    }

    private func submitJob(
        prompt: String,
        image: UIImage?,
        endImage: UIImage?,
        duration: String,
        quality: String,
        ratio: String
    ) async throws -> SubmitResult {

        let apiKey = AIConfig.shared.openRouterApiKey
        guard !apiKey.isEmpty else { throw VideoError.missingApiKey }

        // 统一使用 chat/completions 路径
        let base = AIConfig.shared.openRouterBaseURL
        let urlString = base.hasSuffix("/") ? "\(base)chat/completions" : "\(base)/chat/completions"
        guard let url = URL(string: urlString) else { throw VideoError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)",   forHTTPHeaderField: "Authorization")
        request.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        request.setValue("AIDream-iOS",         forHTTPHeaderField: "X-Title")

        // 构造消息内容
        var userContent: [[String: Any]] = [["type": "text", "text": prompt]]

        // 限制参考图尺寸在 512px 以内，显著减小请求体体积
        if let img = image, let b64 = processAndEncodeImage(img, maxDim: 512) {
            userContent.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(b64)"]
            ])
        }

        if let img = endImage, let b64 = processAndEncodeImage(img, maxDim: 512) {
            userContent.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(b64)"]
            ])
        }

        // 构建请求体：视频特有参数放入 extra_body
        let body: [String: Any] = [
            "model": AIConfig.shared.openRouterVideoModel,
            "messages": [["role": "user", "content": userContent]],
            "extra_body": [
                "duration": durationInt(from: duration),
                "aspect_ratio": ratio,
                "resolution": resolution(from: quality)
            ]
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData

        print("📡 [VideoGen] Request Body Size: \(bodyData.count / 1024) KB")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw VideoError.invalidResponse }

        if http.statusCode >= 400 {
            let raw = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("📡 [VideoGen] HTTP \(http.statusCode) Response: \(raw)")
            throw VideoError.serverError("Server (\(http.statusCode)): \(raw.prefix(200))")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VideoError.invalidResponse
        }

        // 1. 尝试解析轮询 URL
        if let pollingPath = json["polling_url"] as? String ?? (json["data"] as? [String: Any])?["polling_url"] as? String,
           let pollingURL = URL(string: pollingPath) {
            return .polling(pollingURL)
        }

        // 2. 尝试解析 ID 构造轮询路径
        if let id = json["id"] as? String ?? (json["data"] as? [String: Any])?["id"] as? String {
            // OpenRouter 视频任务通常在 /generations/{id} 下查询
            let baseWithoutV1 = base.replacingOccurrences(of: "/v1", with: "")
            let pollURLString = "\(baseWithoutV1)/generations/\(id)"
            if let pURL = URL(string: pollURLString) { return .polling(pURL) }
        }

        // 3. 尝试直接获取结果
        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let videoURL = extractVideoURL(from: message) {
            return .completed(videoURL)
        }

        throw VideoError.serverError("Job accepted but result path unknown.")
    }

    private func pollUntilDone(pollingURL url: URL) async throws -> URL {
        let apiKey = AIConfig.shared.openRouterApiKey
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        for attempt in 1...200 {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 5_000_000_000)
            try Task.checkCancellation()

            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { continue }

            let status = (json["status"] as? String ?? (json["data"] as? [String: Any])?["status"] as? String)?.lowercased() ?? "pending"
            print("🔍 [VideoGen] Polling attempt #\(attempt): \(status)")

            state = .generating(min(0.05 + Double(attempt) * 0.005, 0.99))

            if ["completed", "succeeded", "success"].contains(status) {
                let urlStr = (json["unsigned_urls"] as? [String])?.first ??
                             (json["results"] as? [[String: Any]])?.first?["url"] as? String ??
                             ((json["data"] as? [String: Any])?["urls"] as? [String])?.first
                if let urlStr = urlStr, let finalURL = URL(string: urlStr) { return finalURL }
                throw VideoError.urlNotFound
            } else if ["failed", "error", "cancelled"].contains(status) {
                let msg = json["error"] as? String ?? (json["data"] as? [String: Any])?["error"] as? String ?? status
                throw VideoError.serverError(msg)
            }
        }
        throw VideoError.timeout
    }

    private func extractVideoURL(from message: [String: Any]) -> URL? {
        if let video = message["video"] as? [String: Any], let urlStr = video["url"] as? String { return URL(string: urlStr) }
        if let files = message["files"] as? [[String: Any]], let urlStr = files.first?["url"] as? String { return URL(string: urlStr) }
        if let content = message["content"] as? String, content.hasPrefix("http"), content.contains(".mp4") { return URL(string: content) }
        return nil
    }

    private func processAndEncodeImage(_ image: UIImage, maxDim: CGFloat) -> String? {
        var newSize = image.size
        if image.size.width > maxDim || image.size.height > maxDim {
            let ratio = min(maxDim / image.size.width, maxDim / image.size.height)
            newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let data = resizedImage?.jpegData(compressionQuality: 0.5) else { return nil }
        return data.base64EncodedString()
    }

    private func durationInt(from duration: String) -> Int {
        return Int(duration.replacingOccurrences(of: "s", with: "")) ?? 6
    }

    private func resolution(from quality: String) -> String {
        return quality.contains("High") || quality.contains("Ultra") ? "1080p" : "720p"
    }

    enum VideoError: LocalizedError {
        case missingApiKey, invalidURL, serverError(String), invalidResponse, urlNotFound, timeout
        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "API Key Missing"
            case .serverError(let s): return "Server: \(s)"
            case .timeout: return "Timeout"
            default: return "Generation failed."
            }
        }
    }
}
