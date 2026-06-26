import Foundation
import OSLog
import FirebaseRemoteConfig

class AIConfig {
    static let shared = AIConfig()

    private let remoteConfig = RemoteConfig.remoteConfig()
    private let logger = Logger(subsystem: "com.aidream.app", category: "RemoteConfig")

    private init() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        remoteConfig.configSettings = settings

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

    func fetchRemoteConfig() {
        remoteConfig.fetchAndActivate { status, error in
            if let error {
                self.logger.error("Remote Config 获取失败: \(error.localizedDescription)")
                return
            }
            self.logger.info("Remote Config 已激活，状态: \(status.rawValue)")
        }
    }

    func fetchConfigWithTimeout(seconds: Double) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let status = try await self.remoteConfig.fetchAndActivate()
                    self.logger.info("Remote Config Fetch Finished: \(status.rawValue)")
                } catch {
                    self.logger.error("Remote Config Fetch Failed: \(error.localizedDescription)")
                }
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(seconds))
                self.logger.warning("Remote Config Fetch Timeout reached (\(seconds)s)")
            }
            await group.next()
            group.cancelAll()
        }
    }

    // MARK: - 配置访问

    var pollinationsBaseURL: String {
        remoteConfig["pollinationsBaseURL"].stringValue
    }

    var pollinationsApiKey: String {
        remoteConfig["pollinationsApiKey"].stringValue
    }

    var huggingFaceBaseURL: String {
        remoteConfig["huggingFaceBaseURL"].stringValue
    }

    var huggingFaceToken: String {
        remoteConfig["huggingFaceToken"].stringValue
    }

    var huggingFaceVideoModel: String {
        remoteConfig["huggingFaceVideoModel"].stringValue
    }

    var openRouterBaseURL: String {
        remoteConfig["openRouterBaseURL"].stringValue
    }

    var openRouterApiKey: String {
        remoteConfig["openRouterApiKey"].stringValue
    }

    var openRouterImageModel: String {
        remoteConfig["openRouterImageModel"].stringValue
    }

    var openRouterVideoModel: String {
        remoteConfig["openRouterVideoModel"].stringValue
    }

    var privacyPolicyURL: String {
        remoteConfig["privacyPolicyURL"].stringValue
    }

    var termsOfServiceURL: String {
        remoteConfig["termsOfServiceURL"].stringValue
    }
}