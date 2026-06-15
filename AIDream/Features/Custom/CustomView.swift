import SwiftUI

enum GenerationMode {
    case imageToVideo
    case reference
    case textToImage
}

struct CustomView: View {
    @State private var selectedMode: GenerationMode = .imageToVideo
    @State private var showTip = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                AppTheme.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    customNavBar
                    modeSelector

                    ZStack {
                        switch selectedMode {
                        case .imageToVideo:
                            ImageToVideoView()
                        case .reference:
                            ReferenceVideoView()
                        case .textToImage:
                            TextToImageView()
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        .navigationBarHidden(true)
        .alert("Generation Tips", isPresented: $showTip) {
            Button("Got it") {}
        } message: {
            Text("Video: Upload a start frame image, add a prompt, and AI will animate it.\nReference: Upload reference images to guide the style.\nImage: Describe your vision in words and AI will paint it.")
        }
    }
    }

    // MARK: - Modern Nav Bar
    private var customNavBar: some View {
        HStack {
            // 钻石余额快捷入口
            HStack(spacing: 6) {
                Text("💎")
                Text("\(UserService.shared.diamonds)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))

            Spacer()

            Text(navTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.accentGradH)

            Spacer()

            // 帮助提示
            Button(action: { showTip.toggle() }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.accentSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var navTitle: String {
        switch selectedMode {
        case .imageToVideo: return "Vision Lab"
        case .reference:    return "Style Sync"
        case .textToImage:  return "Dream Canvas"
        }
    }

    // MARK: - Modern Mode Selector (Segmented)
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(
                [GenerationMode.imageToVideo, .reference, .textToImage],
                id: \.self
            ) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selectedMode = mode }
                } label: {
                    VStack(spacing: 8) {
                        Text(modeTitle(for: mode))
                            .font(.system(size: 15, weight: selectedMode == mode ? .bold : .medium))
                            .foregroundColor(selectedMode == mode ? .white : AppTheme.textMuted)

                        if selectedMode == mode {
                            Capsule()
                                .fill(AppTheme.accentGradH)
                                .frame(width: 24, height: 3)
                                .matchedGeometryEffect(id: "tab", in: tabNamespace)
                        } else {
                            Capsule()
                                .fill(Color.clear)
                                .frame(width: 24, height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .background(AppTheme.bgPrimary)
    }

    @Namespace private var tabNamespace

    private func modeTitle(for mode: GenerationMode) -> String {
        switch mode {
        case .imageToVideo: return "Video"
        case .reference:    return "Reference"
        case .textToImage:  return "Image"
        }
    }
}
