import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0 // 默认选中 Explore
    @State private var customSelectedMode: GenerationMode = .imageToVideo

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.bgPrimary.ignoresSafeArea()

            // Page content
            Group {
                switch selectedTab {
                case 0:  VideoListViewWrapper().ignoresSafeArea(edges: .top)
                case 1:  CustomView(externalMode: $customSelectedMode)
                default: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .switchToReferenceMode)) { _ in
            customSelectedMode = .reference
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = 1
            }
        }
    }

    // MARK: - HypeCut Style Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "square.grid.2x2.fill", label: "Explore", index: 0)
            tabItem(icon: "wand.and.stars",       label: "Create",  index: 1)
            tabItem(icon: "person.crop.circle",   label: "Profile", index: 2)
        }
        .frame(height: 55)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .glassStyle(cornerRadius: 24)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private func tabItem(icon: String, label: String, index: Int) -> some View {
        let active = selectedTab == index
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = index }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // 选中态紫色背景
                    if active {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.accentGrad.opacity(0.2))
                            .frame(width: 86, height: 36)
                    }
                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(active ? AppTheme.accentSecondary : AppTheme.textMuted)
                }
                .frame(width: 86, height: 36)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(active ? AppTheme.accentSecondary : AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Blur View Helper (保留，供其他地方使用)
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
