import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userService = UserService.shared
    @ObservedObject var storeKit = StoreKitService.shared

    @State private var selectedProductID: String = StoreProductID.premiumMonthly.rawValue
    @State private var purchasingID: String?
    @State private var appearAnimation = false

    @State private var safariURL: URL?
    @State private var showSafari = false

    // MARK: - 特权项设计
    struct FeatureItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let color: Color
    }

    private let features = [
        FeatureItem(icon: "bolt.fill", title: "Ultra-Fast Generation", description: "Priority server access for AI creation", color: Color(hex: "#FFD700")),
        FeatureItem(icon: "sparkles", title: "4K High Definition", description: "Export your videos in cinematic 4K resolution", color: Color(hex: "#A07BFF")),
        FeatureItem(icon: "diamond.fill", title: "Monthly 1,000 Diamonds", description: "Exclusive monthly claim for Pro members", color: Color(hex: "#6F31D5")),
        FeatureItem(icon: "crown.fill", title: "Pro Style Models", description: "Access to private artistic AI models", color: Color(hex: "#FF8C00"))
    ]

    var body: some View {
        ZStack {
            // MARK: - 沉浸式梦幻背景
            AppTheme.bgPrimary.ignoresSafeArea()

            // 背景装饰光晕
            ZStack {
                Circle()
                    .fill(AppTheme.accentPrimary.opacity(0.15))
                    .frame(width: 450, height: 450)
                    .blur(radius: 100)
                    .offset(x: appearAnimation ? 120 : -120, y: -250)

                Circle()
                    .fill(AppTheme.vipGold.opacity(0.08))
                    .frame(width: 350, height: 350)
                    .blur(radius: 90)
                    .offset(x: appearAnimation ? -150 : 150, y: 150)

                // 飘浮的星光
                ForEach(0..<6) { i in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat.random(in: 2...4))
                        .offset(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -300...300))
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(), value: appearAnimation)
                }
            }
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: appearAnimation)

            VStack(spacing: 0) {
                // 顶部工具栏
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 45) {
                        // 增加了顶部的 padding，防止皇冠光晕被裁切
                        heroSection
                            .padding(.top, 30)

                        featuresList
                        plansSection
                        VStack(spacing: 20) {
                            purchaseButton
                            footerLinks
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                appearAnimation = true
            }
        }
        .sheet(isPresented: $showSafari) {
            if let url = safariURL {
                SafariView(url: url).ignoresSafeArea()
            }
        }
    }

    // MARK: - Components

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            }
            Spacer()
            Button(action: { Task { await storeKit.restorePurchases() } }) {
                Text("Restore")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var heroSection: some View {
        VStack(spacing: 24) {
            ZStack {
                // 核心徽章光晕
                Circle()
                    .fill(AppTheme.vipGold.opacity(0.25))
                    .frame(width: 110, height: 110)
                    .blur(radius: 25)

                Image(systemName: "crown.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.vipGold, Color(hex: "#FFECB3"), AppTheme.vipGold],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppTheme.vipGold.opacity(0.6), radius: 15, x: 0, y: 8)
            }
            .scaleEffect(appearAnimation ? 1.0 : 0.8)
            .rotationEffect(.degrees(appearAnimation ? 0 : -15))

            VStack(spacing: 10) {
                Text("Join AIDream Pro")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)

                Text("Unleash the full power of Visionary AI")
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(features) { feature in
                HStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(feature.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: feature.icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(feature.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(feature.description)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
        }
        .padding(.horizontal, 28)
    }

    private var plansSection: some View {
        VStack(spacing: 16) {
            if storeKit.subscriptionProducts.isEmpty {
                fallbackPlans
            } else {
                ForEach(storeKit.subscriptionProducts, id: \.id) { product in
                    planCard(title: product.displayName, price: product.displayPrice, id: product.id, subTitle: product.description)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var fallbackPlans: some View {
        VStack(spacing: 14) {
            planCard(title: "Weekly", price: "$4.99", id: StoreProductID.premiumWeekly.rawValue, subTitle: "Basic Pro features")
            planCard(title: "Monthly", price: "$12.99", id: StoreProductID.premiumMonthly.rawValue, subTitle: "Includes 1,000 Diamonds", tag: "POPULAR")
            planCard(title: "Annual", price: "$79.99", id: "premium_annual", subTitle: "Save 48% Yearly", tag: "BEST VALUE")
        }
    }

    private func planCard(title: String, price: String, id: String, subTitle: String, tag: String? = nil) -> some View {
        let isSelected = selectedProductID == id
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedProductID = id
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                        Text(subTitle)
                            .font(.system(size: 13))
                            .foregroundColor(isSelected ? .white.opacity(0.7) : AppTheme.textMuted)
                    }

                    Spacer()

                    Text(price)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(isSelected ? AppTheme.vipGold : .white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 22)
                .background(
                    ZStack {
                        if isSelected {
                            // 选中时的背景高亮
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppTheme.vipGold.opacity(0.05))
                        } else {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(isSelected ? AppTheme.vipGold : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
                .scaleEffect(isSelected ? 1.02 : 1.0)

                if let tag = tag {
                    Text(tag)
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isSelected ? AppTheme.vipGold : AppTheme.accentPrimary)
                        .foregroundColor(isSelected ? AppTheme.vipBg : .white)
                        .clipShape(Capsule())
                        .offset(x: -12, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var purchaseButton: some View {
        Button(action: {
            if let product = storeKit.subscriptionProducts.first(where: { $0.id == selectedProductID }) {
                purchasingID = product.id
                Task {
                    let success = await storeKit.purchase(product)
                    purchasingID = nil
                    if success { dismiss() }
                }
            }
        }) {
            ZStack {
                if purchasingID != nil {
                    ProgressView().tint(AppTheme.vipBg)
                } else {
                    Text(userService.isPremium ? "Active Subscription" : "Unlock My Potential")
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(
                LinearGradient(
                    colors: [AppTheme.vipGold, Color(hex: "#FFD700")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .foregroundColor(AppTheme.vipBg)
            .clipShape(Capsule())
            .shadow(color: AppTheme.vipGold.opacity(0.4), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 30)
        }
        .disabled(userService.isPremium || purchasingID != nil)
    }

    private var footerLinks: some View {
        VStack(spacing: 12) {
            Text("Cancel anytime in App Store. No hidden fees.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 20) {
                Button("Terms") {
                    safariURL = URL(string: AIConfig.shared.termsOfServiceURL)
                    showSafari = true
                }
                Circle().fill(AppTheme.textMuted).frame(width: 3, height: 3)
                Button("Privacy") {
                    safariURL = URL(string: AIConfig.shared.privacyPolicyURL)
                    showSafari = true
                }
                Circle().fill(AppTheme.textMuted).frame(width: 3, height: 3)
                Button("Restore") {
                    Task { await storeKit.restorePurchases() }
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AppTheme.textMuted)
        }
    }
}
