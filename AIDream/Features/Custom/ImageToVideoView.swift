import SwiftUI

struct ImageToVideoView: View {
    @State private var promptText: String = ""
    @State private var selectedDuration: String = "5s"
    @State private var selectedQuality: String = "Standard"
    @State private var selectedRatio: String = "9:16"

    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景 - id: ECLB2
            Color(hex: "#0c0c0c").ignoresSafeArea()

            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        // 图片上传区 - id: MyHjl
                        imageUploadSection
                            .padding(.top, 32)

                        // Prompt 区 - id: uFgsR
                        promptSection

                        // 视频参数区 - id: qzl9W & dTtQW
                        VStack(spacing: 24) {
                            optionRow(title: "Duration", options: ["5s", "10s"], selection: $selectedDuration, proOptions: ["10s"])
                            optionRow(title: "Quality", options: ["Standard", "High", "Ultra HD"], selection: $selectedQuality, proOptions: ["High", "Ultra HD"])

                            // 画面比例 - id: Li84b
                            aspectRatioSection
                        }

                        Spacer(minLength: 180)
                    }
                    .padding(.horizontal, 16)
                }
            }

            // 底部操作区 - id: yUxk8
            bottomActionSection
        }
    }

    // MARK: - Image Section
    private var imageUploadSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                imageCard(title: "Start", image: "portrait_placeholder", id: "aHatA")
                imageCard(title: "End", image: nil, id: "Xj07D")
            }
            .frame(maxWidth: .infinity)

            Text("Source Image (Optional)") // id: AcmRt
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }

    private func imageCard(title: String, image: String?, id: String) -> some View {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
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

    // MARK: - Prompt Section
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("prompt")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 140)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))

                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if promptText.isEmpty {
                    Text("Describe the scene, action, and style...")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Options Helper
    private func optionRow(title: String, options: [String], selection: Binding<String>, proOptions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    Button(action: { selection.wrappedValue = opt }) {
                        HStack(spacing: 4) {
                            Text(opt)
                            if proOptions.contains(opt) {
                                Text("PRO")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(LinearGradient(colors: [Color(hex: "#c260f5"), Color(hex: "#6034e4")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .clipShape(Capsule())
                            }
                        }
                        .font(.system(size: 15, weight: selection.wrappedValue == opt ? .bold : .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(selection.wrappedValue == opt ? Color(hex: "#7032d6") : Color.white.opacity(0.05))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Aspect Ratio
    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("aspect ratio")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))

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
                    Image(systemName: icon)
                        .font(.system(size: 20))

                    Text("PRO")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .background(LinearGradient(colors: [Color(hex: "#c260f5"), Color(hex: "#6034e4")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Capsule())
                        .offset(x: 12, y: -8)
                }
                Text(label)
                    .font(.system(size: 15, weight: isSelected ? .bold : .regular))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? Color(hex: "#7032d6") : Color.white.opacity(0.05))
            .cornerRadius(20)
        }
    }

    // MARK: - Bottom Section
    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Want faster generation?")
                    .foregroundColor(.white.opacity(0.4))
                Text("Get SVIP (50% OFF).")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "#ffa8a8"), Color(hex: "#fcff00")], startPoint: .leading, endPoint: .trailing))
            }
            .font(.system(size: 12))

            Button(action: {}) {
                VStack(spacing: 4) {
                    Text("Generate Video")
                        .font(.system(size: 18, weight: .bold))

                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 12))
                        Text("200")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "#ffa8a8"), Color(hex: "#fcff00")], startPoint: .leading, endPoint: .trailing))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(LinearGradient(colors: [Color(hex: "#c260f5"), Color(hex: "#6034e4")], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(22)
            }

            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.white.opacity(0.8))
                Text("Failed task? 100% Refund.")
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "#fc98ff"), Color(hex: "#95d7ff")], startPoint: .leading, endPoint: .trailing))
            }
            .font(.system(size: 12))
        }
        .padding(20)
        .padding(.bottom, 20)
        .background(
            Color(hex: "#252428").opacity(0.6)
                .background(.ultraThinMaterial)
        )
    }
}
