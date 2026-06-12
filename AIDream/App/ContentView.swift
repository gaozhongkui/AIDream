import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 1 // 默认选中 Create

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

    // MARK: - Modern Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "square.grid.2x2.fill", label: "Explore", index: 0)
            tabItem(icon: "wand.and.stars",       label: "Create",  index: 1)
            tabItem(icon: "person.crop.circle",   label: "Profile", index: 2)
        }
        .frame(height: 72)
        .padding(.horizontal, 24)
        .background(
            ZStack {
                BlurView(style: .systemUltraThinMaterialDark)
                    .clipShape(Capsule())
                Capsule()
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.4), radius: 15, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 24) // 悬浮距离底部的间距
    }

    private func tabItem(icon: String, label: String, index: Int) -> some View {
        let active = selectedTab == index
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = index }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: active ? .bold : .medium))
                    .foregroundStyle(active
                        ? AnyShapeStyle(AppTheme.accentGradV)
                        : AnyShapeStyle(AppTheme.textMuted))
                    .scaleEffect(active ? 1.15 : 1.0)

                Text(label)
                    .font(.system(size: 11, weight: active ? .bold : .medium))
                    .foregroundColor(active ? .white : AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Blur View Helper
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
