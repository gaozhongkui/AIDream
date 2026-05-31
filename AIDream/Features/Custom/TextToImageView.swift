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
                VStack(alignment: .leading, spacing: 24) {
                    displaySection

                    promptSection

                    imageOptions

                    Spacer(minLength: 100)
                }
                .padding(20)
            }

            bottomActionSection
        }
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
                    .background(Color(white: 0.15))
                    .cornerRadius(24)
                } else {
                    Image("portrait_placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
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

            Text(generatedImage != nil ? "Generated Result" : "Source Image (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

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
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color(white: 0.12))
                    .cornerRadius(20)
                    .overlay(
                        Text(promptText.isEmpty ? "Describe the scene, action, and style..." : "")
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                            .padding(.top, 20)
                        , alignment: .topLeading
                    )

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("AI Expand")

                    Text("SVIP")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                        .offset(y: -10)
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .padding(10)
            }
        }
    }

    private var imageOptions: some View {
        VStack(alignment: .leading, spacing: 20) {
            optionHeader(title: "Aspect Ratio", showSVIP: false)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ratioButton(ratio: "1:1", icon: "square")
                    ratioButton(ratio: "3:4", icon: "rectangle.portrait")
                    ratioButton(ratio: "4:3", icon: "rectangle")
                    ratioButton(ratio: "16:9", icon: "rectangle.fill")
                }
            }

            optionHeader(title: "Number Of Images", showSVIP: false)
            HStack {
                Button(action: { if imageCount > 1 { imageCount -= 1 } }) {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                }

                Spacer()
                Text("\(imageCount) Images")
                    .font(.system(size: 16, weight: .bold))
                Spacer()

                Button(action: { imageCount += 1 }) {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(white: 0.1))
            .cornerRadius(16)
        }
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                Text("Want faster generation?")
                    .foregroundColor(.gray)
                Text("Get SVIP (50% OFF).")
                    .foregroundColor(.yellow)
            }
            .font(.system(size: 14))

            Button(action: {
                generateImage()
            }) {
                VStack(spacing: 2) {
                    Text("Generate Image")
                        .font(.system(size: 18, weight: .bold))

                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 14))
                        Text("40")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(32)
                .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.purple)
                Text("Failed task? 100% Refund.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(
            Color(red: 18/255, green: 18/255, blue: 18/255)
                .shadow(color: .black.opacity(0.5), radius: 20, y: -10)
        )
    }

    private func optionHeader(title: String, showSVIP: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
            if showSVIP {
                Text("SVIP")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(4)
            }
        }
    }

    private func ratioButton(ratio: String, icon: String) -> some View {
        Button(action: { selectedRatio = ratio }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(ratio)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(selectedRatio == ratio ? .white : .gray)
            .frame(width: 80, height: 80)
            .background(selectedRatio == ratio ? Color.purple : Color(white: 0.12))
            .cornerRadius(20)
        }
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
