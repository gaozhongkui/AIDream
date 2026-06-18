import SwiftUI

enum GenerationMode {
    case imageToVideo
    case reference
    case textToImage
}

struct CustomView: View {
    @Binding var externalMode: GenerationMode
    @State private var selectedMode: GenerationMode = .imageToVideo
    @State private var showTip = false
    @State private var hasSyncedExternal = false
    @ObservedObject var userService = UserService.shared

    init(externalMode: Binding<GenerationMode> = .constant(.imageToVideo)) {
        self._externalMode = externalMode
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                AppTheme.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    customNavBar
                    modeSelector

                    ZStack(alignment: .top) {
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
            .onChange(of: externalMode) { newMode in
                if !hasSyncedExternal {
                    hasSyncedExternal = true
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = newMode
                    }
                }
            }
            .alert("Generation Tips", isPresented: $showTip) {
                Button("Got it") {}
            } message: {
                Text("Video: Upload a start frame image, add a prompt, and AI will animate it.\nReference: Upload reference images to guide the style.\nImage: Describe your vision in words and AI will paint it.")
            }
        }
    }

    // MARK: - Nav Bar
    private var customNavBar: some View {
        HStack {
            // 钻石余额快捷入口
            NavigationLink(destination: DiamondStoreView()) {
                HStack(spacing: 6) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.accentGrad)
                    Text("\(userService.diamonds)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassStyle(cornerRadius: 20)
            }

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
                    .glassStyle(cornerRadius: 20)
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

    // MARK: - HypeCut Style Mode Selector
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(
                [GenerationMode.imageToVideo, .reference, .textToImage],
                id: \.self
            ) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selectedMode = mode }
                } label: {
                    Text(modeTitle(for: mode))
                        .font(.system(size: 15, weight: selectedMode == mode ? .bold : .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(
                            selectedMode == mode
                                ? RoundedRectangle(cornerRadius: 10).fill(AppTheme.accentPrimary)
                                : RoundedRectangle(cornerRadius: 8).fill(Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .glassStyle(cornerRadius: 14)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func modeTitle(for mode: GenerationMode) -> String {
        switch mode {
        case .imageToVideo: return "Video"
        case .reference:    return "Reference"
        case .textToImage:  return "Image"
        }
    }
}
