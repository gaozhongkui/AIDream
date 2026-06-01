import SwiftUI

struct TextToImageView: View {
    @State private var promptText: String = ""
    @State private var selectedRatio: String = "1:1"
    @State private var imageCount: Int = 3

    // 生成状态
    @State private var isGenerating: Bool = false
    @State private var generationProgress: Double = 0
    @State private var completedImage: UIImage? = nil
    @State private var errorMessage: String? = nil
    @State private var showCompletion: Bool = false

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            // ── 滚动内容区 ──
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // 报错提示（生成失败时显示）
                    if let error = errorMessage {
                        errorBanner(error)
                    }

                    promptSection
                    aspectRatioSection
                    imageCountSection
                    Spacer(minLength: 140)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }

            // ── 底部操作栏（固定底部）──
            VStack {
                Spacer()
                if !isGenerating {
                    bottomActionSection
                }
            }

            // ── 生成中全屏遮罩 ──
            if isGenerating {
                GeneratingView(
                    progress: generationProgress,
                    onBackToHome: {
                        AIImageGenerator.shared.cancelGeneration()
                        isGenerating = false
                        generationProgress = 0
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        // ── 生成完成全屏展示 ──
        .fullScreenCover(isPresented: $showCompletion) {
            if let image = completedImage {
                VideoCompletionView(
                    media: .image(image),
                    onClose: {
                        showCompletion = false
                        completedImage = nil
                    },
                    onRetake: {
                        showCompletion = false
                        completedImage = nil
                    },
                    onDownload: {
                        if let img = completedImage {
                            saveImage(img)
                        }
                    },
                    onShare: {
                        if let img = completedImage {
                            shareImage(img)
                        }
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isGenerating)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.error)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.error)
                .lineLimit(2)
            Spacer()
            Button { errorMessage = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(12)
        .background(AppTheme.error.opacity(0.1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(AppTheme.error.opacity(0.3), lineWidth: 0.5))
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROMPT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2).padding(.leading, 4)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.bgCard)
                    .cornerRadius(18)
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.borderSubtle, lineWidth: 0.5))
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if promptText.isEmpty {
                    Text("Describe the scene, style and mood…")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.leading, 16).padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Aspect Ratio

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ASPECT RATIO")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2).padding(.leading, 4)

            HStack(spacing: 8) {
                ratioButton(ratio: "1:1",  icon: "square")
                ratioButton(ratio: "3:4",  icon: "rectangle.portrait")
                ratioButton(ratio: "4:3",  icon: "rectangle")
                ratioButton(ratio: "16:9", icon: "rectangle.fill")
            }
        }
    }

    private func ratioButton(ratio: String, icon: String) -> some View {
        let selected = selectedRatio == ratio
        return Button { selectedRatio = ratio } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20))
                Text(ratio).font(.system(size: 13, weight: selected ? .bold : .regular))
            }
            .foregroundColor(selected ? AppTheme.goldBright : AppTheme.textSecondary)
            .frame(maxWidth: .infinity).frame(height: 76)
            .optionStyle(selected: selected, cornerRadius: 18)
        }
    }

    // MARK: - Image Count

    private var imageCountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NUMBER OF IMAGES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2).padding(.leading, 4)

            HStack {
                Button { if imageCount > 1 { imageCount -= 1 } } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.goldMid)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.goldBright.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.borderGold, lineWidth: 1))
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("\(imageCount)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.goldGradH)
                    Text("Images")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Button { if imageCount < 10 { imageCount += 1 } } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.goldMid)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.goldBright.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.borderGold, lineWidth: 1))
                }
            }
            .padding(12)
            .background(AppTheme.bgCard)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.borderSubtle, lineWidth: 0.5))
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

            Button { generateImage() } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles").font(.system(size: 17))
                        Text("Generate Image").font(.system(size: 17, weight: .bold))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill").font(.system(size: 11))
                        Text("40").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "#0A0A0A"))
                }
                .foregroundColor(Color(hex: "#0A0A0A"))
                .frame(maxWidth: .infinity).frame(height: 60)
                .background(AppTheme.goldGradH)
                .cornerRadius(22)
                .shadow(color: AppTheme.goldGlow, radius: 12, y: 5)
            }
            .disabled(promptText.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(promptText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)

            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(AppTheme.goldGradH)
                Text("Failed task? 100% Refund.").foregroundColor(AppTheme.textSecondary)
            }
            .font(.system(size: 12))
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 20)
        .background(
            ZStack {
                AppTheme.bgSecondary
                Color.white.opacity(0.015)
            }
            .overlay(Rectangle().fill(AppTheme.borderSubtle).frame(height: 0.5), alignment: .top)
        )
    }

    // MARK: - 生成逻辑

    private func generateImage() {
        let trimmed = promptText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isGenerating = true
        errorMessage = nil
        generationProgress = 0.05

        var options = AIImageGenerator.GenerationOptions.default
        switch selectedRatio {
        case "1:1":  options.width = 1024; options.height = 1024
        case "3:4":  options.width = 768;  options.height = 1024
        case "4:3":  options.width = 1024; options.height = 768
        case "16:9": options.width = 1024; options.height = 576
        default: break
        }

        AIImageGenerator.shared.generateImage(
            prompt: trimmed,
            options: options,
            onStateChange: { [self] state in
                // 将 AIImageGenerator 的状态映射为进度值
                switch state {
                case .preparing:           generationProgress = 0.08
                case .requesting:          generationProgress = 0.25
                case .downloading(let p):  generationProgress = 0.25 + p * 0.65
                case .processing:          generationProgress = 0.95
                default: break
                }
            },
            onProgress: { [self] p in
                // downloading 进度补充更新
                generationProgress = max(generationProgress, 0.25 + p * 0.65)
            }
        ) { [self] result in
            isGenerating = false
            switch result {
            case .success(let res):
                completedImage = res.image
                generationProgress = 1.0
                // 短暂延迟让进度动画走完
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCompletion = true
                }
            case .failure(let err):
                errorMessage = err.localizedDescription
                generationProgress = 0
            }
        }
    }

    // MARK: - 保存 / 分享

    private func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    private func shareImage(_ image: UIImage) {
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(vc, animated: true)
    }
}
