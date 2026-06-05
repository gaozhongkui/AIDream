//
//  AIDreamApp.swift
//  AIDream
//
//  Created by  高中奎 on 2026/5/28.
//

import SwiftUI

@main
struct AIDreamApp: App {
    @State private var showLaunch = true

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
                // 启动页展示 2.5 秒后切换到主界面
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showLaunch = false
                    }
                }
            }
        }
    }
}
