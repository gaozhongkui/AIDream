import SwiftUI

enum GenerationMode {
    case imageToVideo
    case reference
    case textToImage
}

struct CustomView: View {
    @State private var selectedMode: GenerationMode = .imageToVideo

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(hex: "#0c0c0c").ignoresSafeArea()

                VStack(spacing: 0) {
                    // 顶部导航栏
                    customNavBar

                    // 模式切换器
                    modeSelector

                    // 页面内容 (内部自带 ScrollView 和 底部按钮)
                    ZStack {
                        if selectedMode == .imageToVideo {
                            ImageToVideoView()
                        } else if selectedMode == .reference {
                            ReferenceVideoView()
                        } else {
                            TextToImageView()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var customNavBar: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#868095").opacity(0.2))
                    .clipShape(Circle())
            }
            Spacer()
            Text(navTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button(action: {}) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#868095").opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var navTitle: String {
        switch selectedMode {
        case .imageToVideo: return "Create Video"
        case .reference: return "Reference Video"
        case .textToImage: return "Create Image"
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach([GenerationMode.imageToVideo, GenerationMode.reference, GenerationMode.textToImage], id: \.self) { mode in
                Button(action: { selectedMode = mode }) {
                    VStack(spacing: 8) {
                        Text(modeTitle(for: mode))
                            .font(.system(size: 15, weight: selectedMode == mode ? .bold : .medium))
                            .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.4))

                        if selectedMode == mode {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "#7032d6"))
                                .frame(width: 40, height: 3)
                        } else {
                            Color.clear.frame(height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 15)
    }

    private func modeTitle(for mode: GenerationMode) -> String {
        switch mode {
        case .imageToVideo: return "Image to Video"
        case .reference: return "Reference"
        case .textToImage: return "Text to Image"
        }
    }
}
