//
//  AIDreamApp.swift
//  AIDream
//
//  Created by  高中奎 on 2026/5/28.
//

import SwiftUI
import FirebaseCore
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "App")

@main
struct AIDreamApp: App {
    @State private var showLaunch = true

    init() {
        // Initialize Firebase
        FirebaseApp.configure()

        // Initialize network monitor to start tracking connectivity
        _ = NetworkMonitor.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunch {
                    LaunchView()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                startAppLaunchSequence()
            }
        }
    }

    /// 启动序列：并行执行配置获取和最小等待时间
    private func startAppLaunchSequence() {
        logger.info("🚀 启动序列开始...")
        Task {
            let startTime = Date()

            // 1. 请求远程配置 (设置 3 秒超时)
            logger.info("🌐 开始同步云端配置...")
            await AIConfig.shared.fetchConfigWithTimeout(seconds: 3.0)

            // 2. 确保配置下发后，再触发首次安装赠送逻辑
            await UserService.shared.checkAndApplyWelcomeGift()

            logger.info("✅ 同步序列完成")

            // 2. 确保闪屏动画至少展示 2.0 秒
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDisplayTime: Double = 2.0
            if elapsed < minimumDisplayTime {
                let remaining = minimumDisplayTime - elapsed
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }

            logger.info("📱 进入主界面")
            // 3. 切换到主界面
            withAnimation(.easeInOut(duration: 0.5)) {
                showLaunch = false
            }
        }
    }
}
