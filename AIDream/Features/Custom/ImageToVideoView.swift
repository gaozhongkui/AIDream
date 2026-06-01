import SwiftUI

struct ImageToVideoView: View {
    @State private var promptText: String = ""
    @State private var selectedDuration: String = "6s"
    @State private var selectedQuality: String = "Standard"
    @State private var selectedRatio: String = "9:16"

    @ObservedObject private var videoGenerator = AIVideoGenerator.shared

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            // ── 滚动内容区 ──
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    imageUploadSection.padding(.top, 16)
                    promptSection
                    VStack(spacing: 22) {
                        optionRow(title: "Duration",
                                  options: ["6s", "10s"],
                                  selection: $selectedDuration,
                                  proOptions: ["10s"])
                        optionRow(title: "Quality",
                                  options: ["Standard", "High", "Ultra HD"],
                                  selection: $selectedQuality,
                                  proOptions: ["High", "Ultra HD"])
                        aspectRatioSection
                    }
                    Spacer(minLength: 140)   // 为底部操作栏留出空间
                }
                .padding(.horizontal, 16)
            }

            // ── 底部操作栏（固定在底部）──
            VStack {
                Spacer()
                if !isGenerating {
                    bottomActionSection
                }
            }

            // ── 生成中全屏遮罩 ──
            if isGenerating {
                GeneratingView(
                    progress: currentProgress,
                    onBackToHome: { videoGenerator.cancelGeneration() }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        // ── 生成完成全屏展示 ──
        .fullScreenCover(isPresented: completionBinding) {
            if case .completed(let url) = videoGenerator.state {
                VideoCompletionView(
                    media: .video(url),
                    onClose:    { videoGenerator.cancelGeneration() },
                    onRetake:   { videoGenerator.cancelGeneration() },
                    onDownload: { saveVideo(url: url) },
                    onShare:    { shareVideo(url: url) }
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isGenerating)
    }

    // MARK: - Bindings / Helpers

    private var isGenerating: Bool {
        switch videoGenerator.state {
        case .uploading, .generating: return true
        default: return false
        }
    }

    private var currentProgress: Double {
        if case .generating(let p) = videoGenerator.state { return p }
        return 0.05
    }

    private var completionBinding: Binding<Bool> {
        Binding(
            get: { if case .completed = videoGenerator.state { return true } else { return false } },
            set: { if !$0 { videoGenerator.cancelGeneration() } }
        )
    }

    private func saveVideo(url: URL) {
        // TODO: 保存到相册
        print("[ImageToVideo] Save video: \(url)")
    }

    private func shareVideo(url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(vc, animated: true)
    }

    // MARK: - 图片上传区

    private var imageUploadSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                imageCard(title: "Start", image: "portrait_placeholder")
                imageCard(title: "End",   image: nil)
            }
            Text("Source Image (Optional)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.leading, 4)
        }
    }

    private func imageCard(title: String, image: String?) -> some View {
        ZStack(alignment: .topLeading) {
            if let name = image {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 136)
                    .cornerRadius(18)
                    .clipped()
                    .goldBorder(cornerRadius: 18, active: true)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.goldGrad)
                    Text("Add End Frame")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
                .frame(width: 106, height: 136)
                .background(AppTheme.bgCard)
                .cornerRadius(18)
                .goldBorder(cornerRadius: 18, active: false)
            }

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .padding(8)
        }
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROMPT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2)
                .padding(.leading, 4)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.bgCard)
                    .frame(height: 140)
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.borderSubtle, lineWidth: 0.5))

                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if promptText.isEmpty {
                    Text("Describe the scene, action and style…")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Options

    private func optionRow(
        title: String,
        options: [String],
        selection: Binding<String>,
        proOptions: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2)
                .padding(.leading, 4)

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    Button { selection.wrappedValue = opt } label: {
                        HStack(spacing: 5) {
                            Text(opt)
                                .font(.system(size: 14,
                                    weight: selection.wrappedValue == opt ? .bold : .regular))
                                .foregroundColor(.white)
                            if proOptions.contains(opt) { proTag }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .optionStyle(selected: selection.wrappedValue == opt)
                    }
                }
            }
        }
    }

    private var proTag: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 5).padding(.vertical, 2)
            .foregroundColor(Color(hex: "#0A0A0A"))
            .background(AppTheme.goldGradH)
            .clipShape(Capsule())
    }

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ASPECT RATIO")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2)
                .padding(.leading, 4)

            HStack(spacing: 8) {
                ratioButton(label: "9:16", icon: "iphone",
                            isSelected: selectedRatio == "9:16") { selectedRatio = "9:16" }
                ratioButton(label: "1:1",  icon: "square",
                            isSelected: selectedRatio == "1:1")  { selectedRatio = "1:1" }
            }
        }
    }

    private func ratioButton(label: String, icon: String,
                              isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon).font(.system(size: 20))
                    proTag.offset(x: 12, y: -8)
                }
                Text(label).font(.system(size: 13, weight: isSelected ? .bold : .regular))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 64)
            .optionStyle(selected: isSelected, cornerRadius: 18)
        }
    }

    // MARK: - 底部操作栏

    private var bottomActionSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 5) {
                Text("Want faster generation?").foregroundColor(AppTheme.textMuted)
                Text("Get SVIP (50% OFF)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.goldGradH)
            }
            .font(.system(size: 12))

            Button {
                videoGenerator.generateVideo(
                    prompt: promptText,
                    image: UIImage(named: "portrait_placeholder"),
                    duration: selectedDuration,
                    quality: selectedQuality,
                    ratio: selectedRatio
                )
            } label: {
                VStack(spacing: 4) {
                    Text("Generate Video")
                        .font(.system(size: 17, weight: .bold))
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill").font(.system(size: 11))
                        Text("200").font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "#0A0A0A"))
                }
                .foregroundColor(Color(hex: "#0A0A0A"))
                .frame(maxWidth: .infinity).frame(height: 60)
                .background(AppTheme.goldGradH)
                .cornerRadius(22)
                .shadow(color: AppTheme.goldGlow, radius: 12, y: 5)
            }

            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(AppTheme.goldGradH)
                Text("Failed task? 100% Refund.").foregroundColor(AppTheme.textSecondary)
            }
            .font(.system(size: 12))
        }
        .padding(20).padding(.bottom, 20)
        .background(
            ZStack {
                AppTheme.bgSecondary
                Color.white.opacity(0.015)
            }
            .overlay(Rectangle().fill(AppTheme.borderSubtle).frame(height: 0.5), alignment: .top)
        )
    }
}
