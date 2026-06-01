import SwiftUI

struct ImageToVideoView: View {
    @State private var promptText: String = ""
    @State private var selectedDuration: String = "5s"
    @State private var selectedQuality: String = "Standard"
    @State private var selectedRatio: String = "9:16"

    // 使用单例管理生成状态
    @ObservedObject private var videoGenerator = AIVideoGenerator.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#0c0c0c").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        // 图片上传区
                        imageUploadSection
                            .padding(.top, 16)

                        // Prompt 区
                        promptSection

                        // 视频参数区
                        VStack(spacing: 24) {
                            optionRow(title: "Duration", options: ["5s", "10s"], selection: $selectedDuration, proOptions: ["10s"])
                            optionRow(title: "Quality", options: ["Standard", "High", "Ultra HD"], selection: $selectedQuality, proOptions: ["High", "Ultra HD"])
                            aspectRatioSection
                        }

                        Spacer(minLength: 180)
                    }
                    .padding(.horizontal, 16)
                }
            }

            // 底部操作区 (已集成进度监听)
            bottomActionSection
        }
        .overlay(
            Group {
                if case .completed(let url) = videoGenerator.state {
                    videoCompletionOverlay(url: url)
                }
            }
        )
    }

    // MARK: - Components

    private var imageUploadSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                imageCard(title: "Start", image: "portrait_placeholder")
                imageCard(title: "End", image: nil)
            }
            .frame(maxWidth: .infinity)

            Text("Source Image (Optional)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.leading, 6) // 对应设计稿 22pt 的视觉偏移
        }
    }

    private func imageCard(title: String, image: String?) -> some View {
        ZStack(alignment: .topLeading) {
            if let imageName = image {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 136)
                    .cornerRadius(20)
                    .clipped()
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.4), lineWidth: 1))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "#fc98ff"), Color(hex: "#95d7ff")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(title == "Start" ? "Add Image" : "Add End Frame")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(width: 106, height: 136)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
                .padding(8)
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("prompt")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .padding(.leading, 6) // 对应设计稿 22pt

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)).frame(height: 140)
                TextEditor(text: $promptText).frame(height: 140).padding(12).scrollContentBackground(.hidden).font(.system(size: 15)).foregroundColor(.white)
                if promptText.isEmpty {
                    Text("Describe the scene, action, and style...").font(.system(size: 15)).foregroundColor(.white.opacity(0.2)).padding(.horizontal, 16).padding(.vertical, 20)
                }
            }
        }
    }

    private func optionRow(title: String, options: [String], selection: Binding<String>, proOptions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 14)).foregroundColor(.white.opacity(0.4)).padding(.leading, 6)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    Button(action: { selection.wrappedValue = opt }) {
                        HStack(spacing: 4) {
                            Text(opt)
                            if proOptions.contains(opt) { proTag }
                        }
                        .font(.system(size: 15, weight: selection.wrappedValue == opt ? .bold : .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(selection.wrappedValue == opt ? Color(hex: "#7032d6") : Color.white.opacity(0.05))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var proTag: some View {
        Text("PRO").font(.system(size: 10, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2)
            .background(LinearGradient(colors: [Color(hex: "#c260f5"), Color(hex: "#6034e4")], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(Capsule())
    }

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("aspect ratio").font(.system(size: 14)).foregroundColor(.white.opacity(0.4)).padding(.leading, 6)
            HStack(spacing: 8) {
                ratioButton(label: "9:16", icon: "iphone", isSelected: selectedRatio == "9:16") { selectedRatio = "9:16" }
                ratioButton(label: "1:1", icon: "square", isSelected: selectedRatio == "1:1") { selectedRatio = "1:1" }
            }
        }
    }

    private func ratioButton(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon).font(.system(size: 20))
                    proTag.offset(x: 12, y: -8)
                }
                Text(label).font(.system(size: 14, weight: isSelected ? .bold : .regular))
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 64)
            .background(isSelected ? Color(hex: "#7032d6") : Color.white.opacity(0.05)).cornerRadius(20)
        }
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Want faster generation?").foregroundColor(.white.opacity(0.4))
                Text("Get SVIP (50% OFF).").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "#ffa8a8"), Color(hex: "#fcff00")], startPoint: .leading, endPoint: .trailing))
            }.font(.system(size: 12))

            Button(action: {
                // 修复：补全 OpenRouter 所需的所有参数
                videoGenerator.generateVideo(
                    prompt: promptText,
                    image: UIImage(named: "portrait_placeholder"),
                    duration: selectedDuration,
                    quality: selectedQuality,
                    ratio: selectedRatio
                )
            }) {
                VStack(spacing: 4) {
                    Text(isGenerating ? "Generating..." : "Generate Video").font(.system(size: 18, weight: .bold))
                    if !isGenerating {
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill").font(.system(size: 12))
                            Text("200").font(.system(size: 14, weight: .bold))
                        }.foregroundStyle(LinearGradient(colors: [Color(hex: "#ffa8a8"), Color(hex: "#fcff00")], startPoint: .leading, endPoint: .trailing))
                    }
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 60)
                .background(isGenerating ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(LinearGradient(colors: [Color(hex: "#c260f5"), Color(hex: "#6034e4")], startPoint: .leading, endPoint: .trailing)))
                .cornerRadius(22)
            }
            .disabled(isGenerating)

            if case .failed(let error) = videoGenerator.state {
                Text(error).font(.system(size: 12)).foregroundColor(.red)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill").foregroundColor(.white.opacity(0.8))
                    Text("Failed task? 100% Refund.")
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "#fc98ff"), Color(hex: "#95d7ff")], startPoint: .leading, endPoint: .trailing))
                }.font(.system(size: 12))
            }
        }
        .padding(20).padding(.bottom, 20)
        .background(Color(hex: "#252428").opacity(0.6).background(.ultraThinMaterial))
    }

    private var isGenerating: Bool {
        switch videoGenerator.state {
        case .uploading, .generating: return true // 修复：移除了 .taskCreated
        default: return false
        }
    }

    private func videoCompletionOverlay(url: URL) -> some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Video Ready!").font(.title2).bold()
                Button("Close") { videoGenerator.cancelGeneration() }.padding().background(Color.purple).cornerRadius(10)
            }.foregroundColor(.white).padding()
        }
    }
}
