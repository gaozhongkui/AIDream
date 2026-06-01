import SwiftUI

struct ReferenceVideoView: View {
    @State private var promptText: String = ""
    @State private var selectedDuration: String = "5s"
    @State private var selectedQuality: String = "Standard"
    @State private var selectedRatio: String = "9:16"

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#0c0c0c").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        // 三槽位参考图上传区
                        referenceImageUploadSection
                            .padding(.top, 32)

                        // Prompt 区
                        promptSection

                        // 视频参数区
                        VStack(spacing: 24) {
                            optionRow(title: "Duration", options: ["5s", "10s"], selection: $selectedDuration, proOptions: ["10s"])
                            optionRow(title: "Quality", options: ["Standard", "High", "Ultra HD"], selection: $selectedQuality, proOptions: ["High", "Ultra HD"])

                            // 画面比例
                            aspectRatioSection
                        }

                        Spacer(minLength: 180)
                    }
                    .padding(.horizontal, 16)
                }
            }

            // 底部操作区 (复用 ImageToVideoView 样式)
            bottomActionSection
        }
    }

    // MARK: - Reference Image Section (3 Slots)
    private var referenceImageUploadSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                // 第一个槽位：虚线 + 亮加号
                referenceImageCard(title: "Add Start Frame", isDashed: true, isProminent: true)

                // 第二个槽位：实线 + 灰加号
                referenceImageCard(title: "Add Image", isDashed: false, isProminent: false)

                // 第三个槽位：实线 + 灰加号
                referenceImageCard(title: "Add Image", isDashed: false, isProminent: false)
            }
            .frame(maxWidth: .infinity)

            Text("Source Image (1-3)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private func referenceImageCard(title: String, isDashed: Bool, isProminent: Bool) -> some View {
        Button(action: {}) {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isProminent ?
                        LinearGradient(colors: [Color(hex: "#fc98ff"), Color(hex: "#95d7ff")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                    )

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(isProminent ? 0.4 : 0.2))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: isDashed ? [4, 4] : []))
                    .foregroundColor(.white.opacity(isDashed ? 0.3 : 0.1))
            )
        }
    }

    // MARK: - Shared Components

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
