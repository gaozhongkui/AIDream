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
                AppTheme.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    customNavBar
                    modeSelector
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

    // MARK: - Nav Bar
    private var customNavBar: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.bgButtonSec)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.borderSubtle, lineWidth: 0.5))
            }

            Spacer()

            Text(navTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.goldGradH)

            Spacer()

            Button(action: {}) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.goldMid)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.bgButtonSec)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.borderSubtle, lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var navTitle: String {
        switch selectedMode {
        case .imageToVideo: return "Create Video"
        case .reference:    return "Reference Video"
        case .textToImage:  return "Create Image"
        }
    }

    // MARK: - Mode Selector
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(
                [GenerationMode.imageToVideo, .reference, .textToImage],
                id: \.self
            ) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedMode = mode }
                } label: {
                    VStack(spacing: 7) {
                        Text(modeTitle(for: mode))
                            .font(.system(size: 14, weight: selectedMode == mode ? .bold : .medium))
                            .foregroundStyle(
                                selectedMode == mode
                                    ? AnyShapeStyle(AppTheme.goldGradH)
                                    : AnyShapeStyle(AppTheme.textMuted)
                            )

                        ZStack {
                            Color.clear.frame(height: 2)
                            if selectedMode == mode {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(AppTheme.goldGradH)
                                    .frame(width: 36, height: 2)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .overlay(
            Rectangle()
                .fill(AppTheme.borderSubtle)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private func modeTitle(for mode: GenerationMode) -> String {
        switch mode {
        case .imageToVideo: return "Image to Video"
        case .reference:    return "Reference"
        case .textToImage:  return "Text to Image"
        }
    }
}
