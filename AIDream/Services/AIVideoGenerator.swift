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
        print("🚀 [VideoGen] Starting process...")

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
                print("✅ [VideoGen] Job Accepted. Polling URL: \(pollingURL)")

                state = .generating(0.05)
                let videoURL = try await pollUntilDone(pollingURL: pollingURL)

                print("🎊 [VideoGen] Success! URL: \(videoURL)")
                state = .completed(videoURL)
            } catch is CancellationError {
                print("ℹ️ [VideoGen] Cancelled.")
            } catch {
                let errorDesc = error.localizedDescription
                print("❌ [VideoGen] Final Error: \(errorDesc)")
                state = .failed(errorDesc)
            }
        }
    }

    func cancelGeneration() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }

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

        // 注意：OpenRouter 的视频接口通常是 /generation 或 /chat/completions 包装的
        // 这里我们尝试最通用的 /videos 路径，但会记录详细错误
        guard let baseURL = URL(string: AIConfig.shared.openRouterBaseURL),
              let url = URL(string: "videos", relativeTo: baseURL) else {
            throw VideoError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)",   forHTTPHeaderField: "Authorization")
        request.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        request.setValue("AIDream-iOS",         forHTTPHeaderField: "X-Title")

        let body: [String: Any] = [
            "model":        AIConfig.shared.openRouterVideoModel,
            "prompt":       prompt,
            "duration":     durationSeconds(from: duration),
            "aspect_ratio": ratio,
            "resolution":   resolution(from: quality),
            "frame_images": [
                frameImagePayload(image: image, frameType: "first_frame"),
                frameImagePayload(image: endImage, frameType: "last_frame")
            ].compactMap { $0 }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📡 [VideoGen] POSTing to \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw VideoError.invalidResponse
        }

        print("📡 [VideoGen] Status Code: \(http.statusCode)")

        // 关键逻辑：即使出错，也先打印出 Body
        if let rawBody = String(data: data, encoding: .utf8) {
            print("📡 [VideoGen] Raw Response: \(rawBody)")
        }

        if http.statusCode >= 400 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw VideoError.serverError(errorMsg)
        }

        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw VideoError.invalidResponse
            }

            // 适配多种返回格式
            if let pollingURLString = json["polling_url"] as? String ?? (json["data"] as? [String: Any])?["polling_url"] as? String,
               let pollingURL = URL(string: pollingURLString, relativeTo: baseURL)?.absoluteURL {
                return pollingURL
            }

            if let id = json["id"] as? String {
                return URL(string: "videos/\(id)", relativeTo: baseURL)!.absoluteURL
            }

            throw VideoError.serverError("Response missing Job ID or Polling URL")
        } catch {
            print("❌ [VideoGen] JSON Parse Error: \(error.localizedDescription)")
            throw error
        }
    }

    private func pollUntilDone(pollingURL url: URL) async throws -> URL {
        let apiKey = AIConfig.shared.openRouterApiKey
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        for attempt in 1...100 { // 延长轮询次数
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 5_000_000_000)
            try Task.checkCancellation()

            print("🔍 [VideoGen] Polling attempt #\(attempt)...")
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                if let raw = String(data: data, encoding: .utf8) {
                    print("⚠️ [VideoGen] Polling non-JSON response: \(raw)")
                }
                continue
            }

            let status = json["status"] as? String ?? (json["data"] as? [String: Any])?["status"] as? String ?? "pending"
            print("   -> Status: \(status)")

            state = .generating(min(0.1 + Double(attempt) * 0.01, 0.98))

            switch status {
            case "completed", "succeeded":
                // 尝试多个可能的视频 URL 路径
                let videoURLString = (json["unsigned_urls"] as? [String])?.first ??
                                     (json["results"] as? [[String: Any]])?.first?["url"] as? String ??
                                     ((json["data"] as? [String: Any])?["urls"] as? [String])?.first

                if let videoURLString = videoURLString, let videoURL = URL(string: videoURLString) {
                    return videoURL
                }
                throw VideoError.urlNotFound

            case "failed", "error", "cancelled":
                let msg = json["error"] as? String ?? (json["data"] as? [String: Any])?["error"] as? String ?? status
                throw VideoError.serverError(msg)

            default:
                continue
            }
        }
        throw VideoError.timeout
    }

    private func durationSeconds(from duration: String) -> Int {
        let s = Int(duration.replacingOccurrences(of: "s", with: "")) ?? 6
        return s <= 6 ? 6 : 10
    }

    private func resolution(from quality: String) -> String {
        return quality.contains("High") || quality.contains("Ultra") ? "1080p" : "720p"
    }

    private func frameImagePayload(image: UIImage?, frameType: String) -> [String: Any]? {
        guard let image, let jpegData = image.jpegData(compressionQuality: 0.7) else { return nil }
        return [
            "type": "image_url",
            "frame_type": frameType,
            "image_url": ["url": "data:image/jpeg;base64,\(jpegData.base64EncodedString())"]
        ]
    }

    enum VideoError: LocalizedError {
        case missingApiKey, invalidURL, serverError(String), invalidResponse, urlNotFound, timeout
        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "API Key Missing"
            case .serverError(let s): return "Server Error: \(s)"
            case .timeout: return "Generation Timeout"
            default: return "Video generation failed. Please try again."
            }
        }
    }
}
