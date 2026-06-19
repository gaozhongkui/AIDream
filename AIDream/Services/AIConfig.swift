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
