import Foundation

struct AIConfig {
    static let shared = AIConfig()

    let pollinationsBaseURL = "https://gen.pollinations.ai/image"
    let pollinationsApiKey = "sk_UhsZmc01AcRpoVcqd9I83kLCJLGy8OS8"

    let huggingFaceBaseURL = "https://api-inference.huggingface.co/models"
    let huggingFaceToken = ""

    let openRouterBaseURL = "https://openrouter.ai/api/v1"
    let openRouterApiKey = "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"
    let openRouterImageModel = "google/gemini-2.5-flash-image"

    // 视频生成模型（OpenRouter 上 MiniMax 的正确 ID）
    let openRouterVideoModel = "minimax/hailuo-2.3"

    private init() {}
}
