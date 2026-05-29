//
//  ContentView.swift
//  AIDream
//
//  Created by  高中奎 on 2026/5/28.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            VideoListViewWrapper()
                .tabItem {
                    Label("视频", systemImage: "video")
                }

            CustomView()
                .tabItem {
                    Label("自定义", systemImage: "plus.circle")
                }

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person")
            }
        }
    }
}
