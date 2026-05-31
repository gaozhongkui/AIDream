import SwiftUI

enum GenerationMode {
    case imageToVideo
    case textToImage
}

struct CustomView: View {
    @State private var selectedMode: GenerationMode = .imageToVideo

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0c0c0c")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 自定义导航栏
                    customNavBar

                    // 模式切换
                    modeSelector

                    if selectedMode == .imageToVideo {
                        ImageToVideoView()
                    } else {
                        TextToImageView()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Components

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

            Text(selectedMode == .imageToVideo ? "Create Video" : "Create Image")
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

    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach([GenerationMode.imageToVideo, GenerationMode.textToImage], id: \.self) { mode in
                Button(action: { selectedMode = mode }) {
                    VStack(spacing: 8) {
                        Text(mode == .imageToVideo ? "Image to Video" : "Text to Image")
                            .font(.system(size: 16, weight: selectedMode == mode ? .bold : .medium))
                            .foregroundColor(selectedMode == mode ? .white : .gray)

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
        .padding(.vertical, 20)
    }
}

struct CustomView_Previews: PreviewProvider {
    static var previews: some View {
        CustomView()
            .preferredColorScheme(.dark)
    }
}
