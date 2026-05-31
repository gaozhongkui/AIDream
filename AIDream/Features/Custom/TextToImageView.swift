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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
        .background(Color(hex: "#0c0c0c"))
    }

    // MARK: - Components

    private var displaySection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                if let image = generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .cornerRadius(24)
                } else if isGenerating {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Generating... \(Int(generationProgress * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(24)
                }

                if generatedImage != nil || isGenerating {
                    Button(action: {
                        if isGenerating {
                            AIImageGenerator.shared.cancelGeneration()
                            isGenerating = false
                        }
                        generatedImage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(10)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("prompt")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .padding(.leading, 6)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )

                if promptText.isEmpty {
                    Text("Describe the scene, action, and style...")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.leading, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("aspect ratio")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .padding(.leading, 6)

            HStack(spacing: 8) {
                ratioButton(ratio: "1:1", icon: "square")
                ratioButton(ratio: "3:4", icon: "rectangle.portrait")
                ratioButton(ratio: "4:3", icon: "rectangle")
                ratioButton(ratio: "16:9", icon: "rectangle.fill")
            }
        }
    }

    private func ratioButton(ratio: String, icon: String) -> some View {
        Button(action: { selectedRatio = ratio }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(ratio)
                    .font(.system(size: 15, weight: selectedRatio == ratio ? .bold : .regular))
            }
            .foregroundColor(selectedRatio == ratio ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(selectedRatio == ratio ? Color(hex: "#7032d6") : Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }

    private var imageCountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("number of images")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .padding(.leading, 6)

            HStack {
                Button(action: { if imageCount > 1 { imageCount -= 1 } }) {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("\(imageCount)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Images")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Button(action: { if imageCount < 10 { imageCount += 1 } }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                Text("Want faster generation?")
                    .foregroundColor(.white.opacity(0.4))
                Text("Get SVIP (50% OFF).")
                    .foregroundColor(Color(hex: "#fcff00"))
                    .font(.system(size: 14, weight: .bold))
            }
            .font(.system(size: 12))

            Button(action: {
                generateImage()
            }) {
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                        Text("Generate Image")
                            .font(.system(size: 18, weight: .bold))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 12))
                        Text("40")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#fcff00"))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(colors: [Color(hex: "#c260f5"), Color(hex: "#6034e4")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(22)
                .shadow(color: Color(hex: "#7032d6").opacity(0.3), radius: 10, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.purple)
                Text("Failed task? 100% Refund.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            Color(hex: "#252428").opacity(0.6)
                .background(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.5), radius: 20, y: -10)
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
        case "1:1": options.width = 1024; options.height = 1024
        case "3:4": options.width = 768; options.height = 1024
        case "4:3": options.width = 1024; options.height = 768
        case "16:9": options.width = 1024; options.height = 576
        default: break
        }

        AIImageGenerator.shared.generateImage(
            prompt: promptText,
            options: options,
            onStateChange: { state in
                print("Generation state: \(state)")
            },
            onProgress: { progress in
                self.generationProgress = progress
            }
        ) { result in
            isGenerating = false
            switch result {
            case .success(let res):
                self.generatedImage = res.image
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
