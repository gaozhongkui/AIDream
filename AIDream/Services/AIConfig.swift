import Foundation
import FirebaseRemoteConfig

class AIConfig {
    static let shared = AIConfig()

    private let remoteConfig = RemoteConfig.remoteConfig()

    private init() {
        // 配置 Remote Config 设置
        let settings = RemoteConfigSettings()
        // 开发阶段可以设置较短的获取间隔，生产环境建议保持默认（12小时）
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600 // 1 小时
        #endif
        remoteConfig.configSettings = settings

        // 设置默认值
        let defaults: [String: NSObject] = [
            "pollinationsBaseURL": "https://gen.pollinations.ai/image" as NSObject,
            "pollinationsApiKey": "sk_UhsZmc01AcRpoVcqd9I83kLCJLGy8OS8" as NSObject,
            "huggingFaceBaseURL": "https://api-inference.huggingface.co/models" as NSObject,
            "huggingFaceToken": "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" as NSObject,
            "huggingFaceVideoModel": "stabilityai/stable-video-diffusion-img2vid-xt" as NSObject,
            "openRouterBaseURL": "https://openrouter.ai/api/v1" as NSObject,
            "openRouterApiKey": "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" as NSObject,
            "openRouterImageModel": "google/gemini-2.5-flash-image" as NSObject,
            "openRouterVideoModel": "minimax/hailuo-2.3" as NSObject,
            "privacyPolicyURL": "https://sites.google.com/view/anima-pic-ai-privacy-policy" as NSObject,
            "termsOfServiceURL": "https://sites.google.com/view/anima-pic-ai-terms-of-service" as NSObject
        ]
        remoteConfig.setDefaults(defaults)
    }

    /// 从 Firebase 获取并激活配置
    func fetchRemoteConfig() {
        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                print("Remote Config 获取失败: \(error.localizedDescription)")
                return
            }
            print("Remote Config 已激活，状态: \(status)")
        }
    }

    /// 带超时机制的获取配置 (用于闪屏页)
    func fetchConfigWithTimeout(seconds: Double) async {
        await withTaskGroup(of: Void.self) { group in
            // 任务 1: 实际的网络请求
            group.addTask {
                do {
                    let status = try await self.remoteConfig.fetchAndActivate()
                    print("Remote Config Fetch Finished: \(status)")
                } catch {
                    print("Remote Config Fetch Failed: \(error)")
                }
            }
            // 任务 2: 强制超时
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                print("Remote Config Fetch Timeout reached (\(seconds)s)")
            }

            // 只要其中一个完成就继续
            await group.next()
            group.cancelAll()
        }
    }

    // MARK: - 获取配置值

    var pollinationsBaseURL: String {
        remoteConfig["pollinationsBaseURL"].stringValue ?? "https://gen.pollinations.ai/image"
    }

    var pollinationsApiKey: String {
        remoteConfig["pollinationsApiKey"].stringValue ?? "sk_UhsZmc01AcRpoVcqd9I83kLCJLGy8OS8"
    }

    var huggingFaceBaseURL: String {
        remoteConfig["huggingFaceBaseURL"].stringValue ?? "https://api-inference.huggingface.co/models"
    }

    var huggingFaceToken: String {
        remoteConfig["huggingFaceToken"].stringValue ?? "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"
    }

    var huggingFaceVideoModel: String {
        remoteConfig["huggingFaceVideoModel"].stringValue ?? "stabilityai/stable-video-diffusion-img2vid-xt"
    }

    var openRouterBaseURL: String {
        remoteConfig["openRouterBaseURL"].stringValue ?? "https://openrouter.ai/api/v1"
    }

    var openRouterApiKey: String {
        remoteConfig["openRouterApiKey"].stringValue ?? "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"
    }

    var openRouterImageModel: String {
        remoteConfig["openRouterImageModel"].stringValue ?? "google/gemini-2.5-flash-image"
    }

    var openRouterVideoModel: String {
        remoteConfig["openRouterVideoModel"].stringValue ?? "minimax/hailuo-2.3"
    }

    var privacyPolicyURL: String {
        remoteConfig["privacyPolicyURL"].stringValue ?? "https://aidream.app/privacy"
    }

    var termsOfServiceURL: String {
        remoteConfig["termsOfServiceURL"].stringValue ?? "https://aidream.app/terms"
    }
}
