import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0 // 默认选中 Explore

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.bgPrimary.ignoresSafeArea()

            // Page content
            Group {
                switch selectedTab {
                case 0:  VideoListViewWrapper()
                case 1:  CustomView()
                default: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .preferredColorScheme(.dark)
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
        .background(
            ZStack {
                // 磨砂玻璃背景
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)

                // 半透明填充层
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "#161418").opacity(0.85))

                // 边框
                RoundedRectangle(cornerRadius: 32)
                    .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
            }
            .shadow(color: Color.black.opacity(0.4), radius: 15, y: 10)
        )
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
                        RoundedRectangle(cornerRadius: 13)
                            .fill(Color(hex: "#7032D6").opacity(0.3))
                            .frame(width: 86, height: 34)
                    }
                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(active ? Color(hex: "#A07BFF") : AppTheme.textMuted)
                }
                .frame(width: 86, height: 34)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(active ? Color(hex: "#A07BFF") : AppTheme.textMuted)
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
