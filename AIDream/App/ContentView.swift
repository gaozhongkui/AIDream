import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

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
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 82) }

            customTabBar
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "play.rectangle.fill", label: "Explore", index: 0)
            tabItem(icon: "sparkles",            label: "Create",  index: 1)
            tabItem(icon: "person.fill",         label: "Profile", index: 2)
        }
        .frame(height: 82)
        .background(
            ZStack(alignment: .top) {
                Color(hex: "#090909")
                    .overlay(Color.white.opacity(0.025))
                // Top gold separator line
                Rectangle()
                    .fill(AppTheme.goldGradH)
                    .frame(height: 0.5)
                    .opacity(0.55)
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabItem(icon: String, label: String, index: Int) -> some View {
        let active = selectedTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selectedTab = index }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if active {
                        Circle()
                            .fill(AppTheme.goldBright.opacity(0.12))
                            .frame(width: 40, height: 40)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: active ? .semibold : .light))
                        .foregroundStyle(active
                            ? AnyShapeStyle(AppTheme.goldGradV)
                            : AnyShapeStyle(AppTheme.textMuted))
                        .scaleEffect(active ? 1.08 : 1.0)
                }
                Text(label)
                    .font(.system(size: 10, weight: active ? .semibold : .regular))
                    .foregroundStyle(active
                        ? AnyShapeStyle(AppTheme.goldMid)
                        : AnyShapeStyle(AppTheme.textMuted))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
    }
}
