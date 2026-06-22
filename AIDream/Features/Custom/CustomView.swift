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
    @State private var showDiamondStore = false
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
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onChange(of: externalMode) { newMode in
                if !hasSyncedExternal {
                    hasSyncedExternal = true
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = newMode
                    }
                }
            }
            .alert(NSLocalizedString("alert_gen_tips_title", comment: ""), isPresented: $showTip) {
                Button(NSLocalizedString("btn_got_it", comment: "")) {}
            } message: {
                Text(NSLocalizedString("alert_gen_tips_msg", comment: ""))
            }
            .fullScreenCover(isPresented: $showDiamondStore) {
                DiamondStoreView()
            }
        }
    }

    // MARK: - Nav Bar
    private var customNavBar: some View {
        HStack {
            // 钻石余额快捷入口
            Button(action: { showDiamondStore = true }) {
                HStack(spacing: 6) {
                    Text("💎")
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
        case .imageToVideo: return NSLocalizedString("nav_vision_lab", comment: "")
        case .reference:    return NSLocalizedString("nav_style_sync", comment: "")
        case .textToImage:  return NSLocalizedString("nav_dream_canvas", comment: "")
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
        case .imageToVideo: return NSLocalizedString("label_video", comment: "")
        case .reference:    return NSLocalizedString("label_reference", comment: "")
        case .textToImage:  return NSLocalizedString("label_image", comment: "")
        }
    }
}
