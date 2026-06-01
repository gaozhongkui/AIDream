import SwiftUI
import UIKit
import Combine

@MainActor
class AIVideoGenerator: ObservableObject {

    // MARK: - 状态定义
    enum VideoGenerationState: Equatable {
        case idle
        case uploading
        case generating(Double)
        case completed(URL)
        case failed(String)

        var description: String {
            switch self {
            case .idle: return "Ready"
            case .uploading: return "Processing image..."
            case .generating(let p): return "AI Generating... \(Int(p * 100))%"
            case .completed: return "Video Ready"
            case .failed(let e): return "Error: \(e)"
            }
        }
    }

    // MARK: - 属性
    @Published var state: VideoGenerationState = .idle

    static let shared = AIVideoGenerator()
    private init() {}

    // MARK: - 核心生成方法

    func generateVideo(prompt: String, image: UIImage?, duration: String, quality: String, ratio: String) {
        Task {
            state = .uploading

            do {
                let request = try buildRequest(prompt: prompt, image: image, duration: duration, quality: quality, ratio: ratio)
                state = .generating(0.15)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    throw VideoError.serverError("OpenRouter Error (HTTP \(code))")
                }

                try await parseResponse(data: data)

            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func cancelGeneration() {
        state = .idle
    }

    // MARK: - 私有助手

    private func buildRequest(prompt: String, image: UIImage?, duration: String, quality: String, ratio: String) throws -> URLRequest {
        let apiKey = AIConfig.shared.openRouterApiKey
        guard !apiKey.isEmpty else { throw VideoError.missingApiKey }

        let endpoint = "\(AIConfig.shared.openRouterBaseURL)/chat/completions"
        guard let url = URL(string: endpoint) else { throw VideoError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AIDream", forHTTPHeaderField: "X-Title")

        var content: [[String: Any]] = [["type": "text", "text": prompt]]
        if let image = image, let base64 = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
            content.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]])
        }

        let body: [String: Any] = [
            "model": AIConfig.shared.openRouterVideoModel,
            "messages": [["role": "user", "content": content]],
            "extra_body": [
                "duration": duration.replacingOccurrences(of: "s", with: ""),
                "video_quality": quality.lowercased(),
                "aspect_ratio": ratio
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseResponse(data: Data) async throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw VideoError.invalidResponse
        }

        if let url = extractVideoURL(from: content) {
            state = .completed(url)
        } else {
            let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if let directURL = URL(string: cleaned), directURL.scheme?.hasPrefix("http") == true {
                state = .completed(directURL)
            } else {
                throw VideoError.urlNotFound
            }
        }
    }

    private func extractVideoURL(from content: String) -> URL? {
        let pattern = "https?://[\\w\\d./?=&%-_]+(.mp4|.mov|.m4v)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) else {
            return nil
        }
        if let range = Range(match.range, in: content) {
            return URL(string: String(content[range]))
        }
        return nil
    }

    enum VideoError: LocalizedError {
        case missingApiKey, invalidURL, serverError(String), invalidResponse, urlNotFound
        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "API Key missing"
            case .invalidURL: return "Invalid endpoint"
            case .serverError(let s): return s
            case .invalidResponse: return "Invalid AI response"
            case .urlNotFound: return "No video URL found"
            }
        }
    }
}
