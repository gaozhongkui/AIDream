import Foundation
import OSLog
import FirebaseRemoteConfig

class AIConfig {
    static let shared = AIConfig()

    private let remoteConfig = RemoteConfig.remoteConfig()
    private let logger = Logger(subsystem: "com.aidream", category: "RemoteConfig")

    private init() {
        setupObservers()
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
            "huggingFaceToken": "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" as NSObject,
            // Gradio Space for image-to-video (configurable via Remote Config)
            "huggingFaceSpaceURL": "https://wangfuyun-animatelcm.hf.space" as NSObject,
            "huggingFaceSpaceFnIndex": 0 as NSObject,
            "openRouterBaseURL": "https://openrouter.ai/api/v1" as NSObject,
            "openRouterApiKey": "" as NSObject,
            "openRouterImageModel": "google/gemini-2.5-flash-image" as NSObject,
            "openRouterVideoModel": "minimax/hailuo-2.3" as NSObject,
            "privacyPolicyURL": "https://sites.google.com/view/anima-pic-ai-privacy-policy" as NSObject,
            "termsOfServiceURL": "https://sites.google.com/view/anima-pic-ai-terms-of-service" as NSObject,
            "initialDiamonds": 200 as NSObject,
            "imageGenerationCost": 100 as NSObject,
            "videoGenerationCost": 500 as NSObject
        ]
        remoteConfig.setDefaults(defaults)
    }

    func fetchRemoteConfig() {
        logger.info("RemoteConfig: 开始获取配置...")
        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("RemoteConfig: 获取异常 - \(error.localizedDescription)")
                return
            }

            // 打印详细状态
            let lastStatus = self.remoteConfig.lastFetchStatus
            self.logger.info("RemoteConfig: 激活状态: \(status.rawValue), 上次获取状态: \(lastStatus.rawValue)")

            // 审计：列出所有从云端拿到的 Key
            let allKeys = self.remoteConfig.allKeys(from: .remote)
            self.logger.info("RemoteConfig: 云端当前包含的 Keys: \(allKeys)")

            if allKeys.contains("initialDiamonds") {
                self.logger.info("RemoteConfig: 成功找到 initialDiamonds, 值: \(self.initialDiamonds)")
            } else {
                self.logger.warning("RemoteConfig: ！！！警告：云端配置中没有找到 'initialDiamonds' 这个 Key ！！！")
            }
        }
    }

    private var isFetching = false

    func fetchConfigWithTimeout(seconds: Double) async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        logger.info("RemoteConfig: 开始异步获取 (超时设定: \(seconds)s)...")
        // ... (保持之前的 fetch 逻辑)

        let success = await withTaskGroup(of: Bool.self) { group in
            // 任务 1: 获取云端配置
            group.addTask {
                do {
                    let _ = try await self.remoteConfig.fetchAndActivate()
                    return true
                } catch {
                    return false
                }
            }

            // 任务 2: 超时控制
            group.addTask {
                try? await Task.sleep(for: .seconds(seconds))
                return false
            }

            let firstResult = await group.next()
            group.cancelAll()
            return firstResult ?? false
        }

        if success {
            logger.info("RemoteConfig: 同步成功，当前 initialDiamonds = \(self.initialDiamonds)")
            NotificationCenter.default.post(name: .remoteConfigActivated, object: nil)
        } else {
            logger.warning("RemoteConfig: 同步超时或失败，将使用本地缓存/默认值")
        }
    }

    private func setupObservers() {
        // 监听网络从无到有的恢复（例如用户在授权框点了允许）
        NotificationCenter.default.addObserver(forName: .networkBecameReachable, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("RemoteConfig: 检测到网络恢复，自动尝试重新同步配置...")
            Task {
                await self.fetchConfigWithTimeout(seconds: 5.0)
            }
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
        "https://api-inference.huggingface.co/models"
    }

    var huggingFaceToken: String {
        remoteConfig["huggingFaceToken"].stringValue
    }

    var huggingFaceSpaceURL: String {
        remoteConfig["huggingFaceSpaceURL"].stringValue
    }

    var huggingFaceSpaceFnIndex: Int {
        Int(remoteConfig["huggingFaceSpaceFnIndex"].numberValue)
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

    var initialDiamonds: Int {
        Int(remoteConfig["initialDiamonds"].numberValue)
    }

    var imageGenerationCost: Int {
        Int(remoteConfig["imageGenerationCost"].numberValue)
    }

    var videoGenerationCost: Int {
        Int(remoteConfig["videoGenerationCost"].numberValue)
    }
}

extension Notification.Name {
    static let remoteConfigActivated = Notification.Name("remoteConfigActivated")
}
