import Foundation

struct AIConfig {
    static let shared = AIConfig()

    let pollinationsBaseURL = "https://gen.pollinations.ai/image"
    let pollinationsApiKey = "sk_UhsZmc01AcRpoVcqd9I83kLCJLGy8OS8"

    let huggingFaceBaseURL = "https://api-inference.huggingface.co/models"
    let huggingFaceToken = ""

    let openRouterBaseURL = "https://openrouter.ai/api/v1"
    let openRouterApiKey = "" // 请在此处填写您的 API Key
    let openRouterImageModel = "google/gemini-2.5-flash-image"

    // 新增视频生成默认模型
    let openRouterVideoModel = "minimax/video-01"

    private init() {}
}
