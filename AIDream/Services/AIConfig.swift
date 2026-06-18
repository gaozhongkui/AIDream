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

    let openRouterVideoModel = "minimax/hailuo-2.3"
    
    // MARK: - Legal URLs
    let privacyPolicyURL = "https://aidream.app/privacy" // 请替换为实际地址
    let termsOfServiceURL = "https://aidream.app/terms"   // 请替换为实际地址

    private init() {}
}
