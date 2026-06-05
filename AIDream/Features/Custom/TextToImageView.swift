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

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    if let error = errorMessage {
                        errorBanner(error)
                    }

                    promptSection.padding(.top, 20)
                    aspectRatioSection
                    imageCountSection

                    Spacer(minLength: 180)
                }
                .padding(.horizontal, 20)
            }

            // ── 悬浮底部生成栏 ──
            VStack {
                Spacer()
                if !isGenerating {
                    bottomActionSection
                }
            }
            .ignoresSafeArea(.keyboard)

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
    }

    // MARK: - Modern Components

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(AppTheme.error)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.error)
            Spacer()
            Button { errorMessage = nil } label: {
                Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
            }
        }
        .padding(16)
        .background(AppTheme.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.error.opacity(0.2), lineWidth: 1))
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Imagination Prompt", systemImage: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.accentSecondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(16)
                    .scrollContentBackground(.hidden)
                    .glassStyle(cornerRadius: 22)
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if promptText.isEmpty {
                    Text("Paint a picture with words... Describe textures, lighting, and emotions.")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CANVAS RATIO")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 10) {
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
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18))
                Text(ratio).font(.system(size: 12, weight: selected ? .bold : .medium))
            }
            .frame(maxWidth: .infinity).frame(height: 70)
            .background(selected ? AppTheme.accentPrimary.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? AppTheme.accentPrimary : Color.clear, lineWidth: 1.5))
            .foregroundColor(selected ? .white : AppTheme.textSecondary)
        }
    }

    private var imageCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ITERATIONS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textMuted)

            HStack {
                stepperButton(icon: "minus") { if imageCount > 1 { imageCount -= 1 } }

                Spacer()

                VStack(spacing: 2) {
                    Text("\(imageCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.accentGrad)
                    Text("Variants")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                stepperButton(icon: "plus") { if imageCount < 10 { imageCount += 1 } }
            }
            .padding(16)
            .glassStyle(cornerRadius: 22)
        }
    }

    private func stepperButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            Button { generateImage() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Render Masterpiece")
                        .font(.system(size: 17, weight: .bold))

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text("40")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.black.opacity(0.2)).clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity).frame(height: 64)
                .background(AppTheme.accentGradH)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: AppTheme.accentGlow, radius: 15, y: 8)
            }
            .disabled(promptText.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(promptText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)

            HStack(spacing: 6) {
                Image(systemName: "sparkles").foregroundColor(AppTheme.accentSecondary)
                Text("AI Artist is ready for your command")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 30)
        .background(LinearGradient(colors: [AppTheme.bgPrimary.opacity(0), AppTheme.bgPrimary], startPoint: .top, endPoint: .bottom))
    }

    // MARK: - Logic (Same as before but wrapped in new UI)

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
                switch state {
                case .preparing:           generationProgress = 0.08
                case .requesting:          generationProgress = 0.25
                case .downloading(let p):  generationProgress = 0.25 + p * 0.65
                case .processing:          generationProgress = 0.95
                default: break
                }
            },
            onProgress: { [self] p in
                generationProgress = max(generationProgress, 0.25 + p * 0.65)
            }
        ) { [self] result in
            isGenerating = false
            switch result {
            case .success(let res):
                completedImage = res.image
                generationProgress = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showCompletion = true }
            case .failure(let err):
                errorMessage = err.localizedDescription
                generationProgress = 0
            }
        }
    }

    private func saveImage(_ image: UIImage) { UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil) }
    private func shareImage(_ image: UIImage) {
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.windows.first?.rootViewController?.present(vc, animated: true)
    }
}
