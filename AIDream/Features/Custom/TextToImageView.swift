import SwiftUI

struct TextToImageView: View {
    @State private var promptText: String = ""
    @State private var selectedRatio: String = "1:1"
    @State private var imageCount: Int = 3

    @State private var generatedImage: UIImage? = nil
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String? = nil
    @State private var generationProgress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if generatedImage != nil || isGenerating {
                        displaySection
                    }
                    promptSection
                    aspectRatioSection
                    imageCountSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }

            bottomActionSection
        }
        .background(AppTheme.bgPrimary)
    }

    // MARK: - Display
    private var displaySection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                if let image = generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .cornerRadius(22)
                        .goldBorder(cornerRadius: 22, active: true)
                } else if isGenerating {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.goldBright))
                        Text("Generating… \(Int(generationProgress * 100))%")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.goldGradH)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(AppTheme.bgCard)
                    .cornerRadius(22)
                    .goldBorder(cornerRadius: 22, active: true)
                }

                Button {
                    if isGenerating {
                        AIImageGenerator.shared.cancelGeneration()
                        isGenerating = false
                    }
                    generatedImage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(10)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
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
                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.bgCard)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
                    )
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if promptText.isEmpty {
                    Text("Describe the scene, action and style…")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.leading, 16)
                        .padding(.top, 20)
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
                .tracking(1.2)
                .padding(.leading, 4)

            HStack(spacing: 8) {
                ratioButton(ratio: "1:1",  icon: "square")
                ratioButton(ratio: "3:4",  icon: "rectangle.portrait")
                ratioButton(ratio: "4:3",  icon: "rectangle")
                ratioButton(ratio: "16:9", icon: "rectangle.fill")
            }
        }
    }

    private func ratioButton(ratio: String, icon: String) -> some View {
        Button { selectedRatio = ratio } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(ratio)
                    .font(.system(size: 13, weight: selectedRatio == ratio ? .bold : .regular))
            }
            .foregroundColor(selectedRatio == ratio ? AppTheme.goldBright : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .optionStyle(selected: selectedRatio == ratio, cornerRadius: 18)
        }
    }

    // MARK: - Image Count
    private var imageCountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NUMBER OF IMAGES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2)
                .padding(.leading, 4)

            HStack {
                Button { if imageCount > 1 { imageCount -= 1 } } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.goldMid)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.goldBright.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.borderGold, lineWidth: 1)
                        )
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.borderGold, lineWidth: 1)
                        )
                }
            }
            .padding(12)
            .background(AppTheme.bgCard)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Bottom Bar
    private var bottomActionSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 5) {
                Text("Want faster generation?")
                    .foregroundColor(AppTheme.textMuted)
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
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(AppTheme.goldGradH)
                .cornerRadius(22)
                .shadow(color: AppTheme.goldGlow, radius: 12, y: 5)
            }

            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(AppTheme.goldGradH)
                Text("Failed task? 100% Refund.")
                    .foregroundColor(AppTheme.textSecondary)
            }
            .font(.system(size: 12))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            ZStack {
                AppTheme.bgSecondary
                Color.white.opacity(0.015)
            }
            .overlay(
                Rectangle()
                    .fill(AppTheme.borderSubtle)
                    .frame(height: 0.5),
                alignment: .top
            )
        )
    }

    // MARK: - Logic
    private func generateImage() {
        guard !promptText.isEmpty else { return }
        isGenerating = true
        errorMessage = nil
        generatedImage = nil

        var options = AIImageGenerator.GenerationOptions.default
        switch selectedRatio {
        case "1:1":  options.width = 1024; options.height = 1024
        case "3:4":  options.width = 768;  options.height = 1024
        case "4:3":  options.width = 1024; options.height = 768
        case "16:9": options.width = 1024; options.height = 576
        default: break
        }

        AIImageGenerator.shared.generateImage(
            prompt: promptText,
            options: options,
            onStateChange: { _ in },
            onProgress: { self.generationProgress = $0 }
        ) { result in
            isGenerating = false
            switch result {
            case .success(let res): self.generatedImage = res.image
            case .failure(let err): self.errorMessage = err.localizedDescription
            }
        }
    }
}
