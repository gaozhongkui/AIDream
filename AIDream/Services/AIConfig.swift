import Foundation

struct AIConfig {
    static let shared = AIConfig()

    let pollinationsBaseURL = "https://gen.pollinations.ai/image"
    let pollinationsApiKey = "sk_UhsZmc01AcRpoVcqd9I83kLCJLGy8OS8"

    let huggingFaceBaseURL = "https://api-inference.huggingface.co/models"
    let huggingFaceToken = "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" 
    let huggingFaceVideoModel = "stabilityai/stable-video-diffusion-img2vid-xt"

    let openRouterBaseURL = "https://openrouter.ai/api/v1"
    let openRouterApiKey = "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"
    let openRouterImageModel = "google/gemini-2.5-flash-image"

    let openRouterVideoModel = "minimax/hailuo-2.3"
    
    // MARK: - Legal URLs
    let privacyPolicyURL = "https://aidream.app/privacy" // 请替换为实际地址
    let termsOfServiceURL = "https://aidream.app/terms"   // 请替换为实际地址

    private init() {}
}
