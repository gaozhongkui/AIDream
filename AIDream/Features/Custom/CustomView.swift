import SwiftUI

struct CustomView: View {
    @State private var promptText: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 顶部的 Banner 或 引导图
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 180)
                        .overlay(
                            VStack {
                                Image(systemName: "sparkles.tv.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                Text("AI 视频实验室")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                        )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("输入你的创意提示词")
                            .font(.headline)

                        TextEditor(text: $promptText)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }

                    Button(action: {
                        // 生成逻辑
                    }) {
                        Text("开始生成视频")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(28)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 10)

                    Text("热门推荐")
                        .font(.headline)
                        .padding(.top, 10)

                    // 简单的横向推荐列表
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<5) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.1))
                                    .frame(width: 140, height: 100)
                                    .overlay(Text("示例场景").font(.caption))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("自定义生成")
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        }
    }
}
