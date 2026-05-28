import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI 梦工厂创作者")
                                .font(.title3.bold())
                            Text("ID: 20240528")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("我的创作") {
                    NavigationLink(destination: Text("创作历史")) {
                        Label("我的视频", systemImage: "video.fill")
                    }
                    NavigationLink(destination: Text("收藏夾")) {
                        Label("收藏灵感", systemImage: "heart.fill")
                    }
                    NavigationLink(destination: Text("草稿箱")) {
                        Label("草稿箱", systemImage: "archivebox.fill")
                    }
                }

                Section("账号与安全") {
                    NavigationLink(destination: Text("个人资料")) {
                        Label("个人资料", systemImage: "person.text.rectangle")
                    }
                    NavigationLink(destination: Text("设置")) {
                        Label("系统设置", systemImage: "gearshape.fill")
                    }
                }

                Section {
                    Button(role: .destructive, action: {}) {
                        HStack {
                            Spacer()
                            Text("退出登录")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}
