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
        FeatureItem(icon: "bolt.fill", title: "Ultra-Fast", description: "Priority access", color: Color(hex: "#FFD700")),
        FeatureItem(icon: "sparkles", title: "4K Video", description: "Cinematic quality", color: Color(hex: "#A07BFF")),
        FeatureItem(icon: "diamond.fill", title: "1,200 Bonus", description: "Monthly claim", color: Color(hex: "#6F31D5")),
        FeatureItem(icon: "crown.fill", title: "Pro Models", description: "Private artistic AI", color: Color(hex: "#FF8C00"))
    ]

    var body: some View {
        ZStack {
            // MARK: - 沉浸式梦幻背景
            AppTheme.bgPrimary.ignoresSafeArea()

            // 背景装饰光晕
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(AppTheme.accentPrimary.opacity(0.15))
                        .frame(width: proxy.size.width * 1.2)
                        .blur(radius: proxy.size.width * 0.2)
                        .offset(x: appearAnimation ? proxy.size.width * 0.3 : -proxy.size.width * 0.3, y: -proxy.size.height * 0.3)

                    Circle()
                        .fill(AppTheme.vipGold.opacity(0.08))
                        .frame(width: proxy.size.width * 0.9)
                        .blur(radius: proxy.size.width * 0.2)
                        .offset(x: appearAnimation ? -proxy.size.width * 0.4 : proxy.size.width * 0.4, y: proxy.size.height * 0.2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: appearAnimation)

            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        heroSection
                            .padding(.top, 100) // 增加顶部间距，适配渐变 Header

                        featuresGrid

                        plansSection

                        VStack(spacing: 20) {
                            purchaseButton
                            footerLinks
                        }
                    }
                    .padding(.bottom, 60)
                }
                .ignoresSafeArea(edges: .top) // 让 ScrollView 内容可以穿透到顶部

                // 顶部工具栏
                headerView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                appearAnimation = true
            }
            // 确保进入页面时同步一次状态
            Task { await storeKit.updateCustomerProductStatus() }
        }
        .sheet(isPresented: $showSafari) {
            if let url = safariURL {
                SafariView(url: url).ignoresSafeArea()
            }
        }
        .alert("Purchase Error", isPresented: Binding(
            get: { storeKit.purchaseError != nil && purchasingID == nil },
            set: { if !$0 { storeKit.purchaseError = nil } }
        )) {
            Button("OK") { storeKit.purchaseError = nil }
        } message: {
            Text(storeKit.purchaseError ?? "")
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
        .padding(.top, 50) // 涵盖状态栏区域
        .padding(.bottom, 20)

    }

    private var heroSection: some View {
        VStack(spacing: 16) { // 减小间距
            ZStack {
                Circle()
                    .fill(AppTheme.vipGold.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .blur(radius: 20)

                Image(systemName: "crown.fill")
                    .font(.system(size: 44)) // 缩小图标
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.vipGold, Color(hex: "#FFECB3"), AppTheme.vipGold],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppTheme.vipGold.opacity(0.6), radius: 10, x: 0, y: 5)
            }
            .scaleEffect(appearAnimation ? 1.0 : 0.8)

            VStack(spacing: 6) {
                Text("AIDream Pro")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)

                Text("Unlock the full potential of AI")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private var featuresGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(features) { feature in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(feature.color.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: feature.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(feature.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(feature.description)
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal, 24)
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            if storeKit.subscriptionProducts.isEmpty {
                fallbackPlans
            } else {
                ForEach(storeKit.subscriptionProducts, id: \.id) { product in
                    let diamondAmount = StoreProductID(rawValue: product.id)?.diamondAmount ?? 0
                    planCard(title: product.displayName,
                             price: product.displayPrice,
                             id: product.id,
                             subTitle: diamondAmount > 0 ? "Includes \(diamondAmount) Diamonds" : product.description)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var fallbackPlans: some View {
        VStack(spacing: 10) {
            planCard(title: "Weekly", price: "$4.99", id: StoreProductID.premiumWeekly.rawValue, subTitle: "500 Diamonds")
            planCard(title: "Monthly", price: "$12.99", id: StoreProductID.premiumMonthly.rawValue, subTitle: "1,200 Diamonds", tag: "POPULAR")
            planCard(title: "Lifetime", price: "$129.99", id: StoreProductID.premiumLifetime.rawValue, subTitle: "10,000 Diamonds & Permanent VIP", tag: "BEST VALUE")
        }
    }

    private func planCard(title: String, price: String, id: String, subTitle: String, tag: String? = nil) -> some View {
        let isSelected = selectedProductID == id
        let isActive = storeKit.purchasedIdentifiers.contains(id)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedProductID = id
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            if isActive {
                                Text("ACTIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                        }

                        Text(subTitle)
                            .font(.system(size: 12))
                            .foregroundColor(isSelected ? .white.opacity(0.7) : AppTheme.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer()

                    Text(price)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(isSelected ? AppTheme.vipGold : .white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.vipGold.opacity(0.05))
                        } else {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isActive ? Color.green.opacity(0.5) : (isSelected ? AppTheme.vipGold : Color.white.opacity(0.1)), lineWidth: (isActive || isSelected) ? 2 : 1)
                )

                if let tag = tag, !isActive {
                    Text(tag)
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isSelected ? AppTheme.vipGold : AppTheme.accentPrimary)
                        .foregroundColor(isSelected ? AppTheme.vipBg : .white)
                        .clipShape(Capsule())
                        .offset(x: -10, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var purchaseButton: some View {
        let isCurrentProductActive = storeKit.purchasedIdentifiers.contains(selectedProductID)

        return Button(action: {
            if storeKit.subscriptionProducts.isEmpty {
                Task { await storeKit.loadProducts() }
                return
            }
            
            guard let product = storeKit.subscriptionProducts.first(where: { $0.id == selectedProductID }) else {
                storeKit.purchaseError = "Product not found. Please try again."
                return
            }
            
            purchasingID = product.id
            Task {
                let success = await storeKit.purchase(product)
                purchasingID = nil
                // 购买成功后不需要立即 dismiss，让用户看到“已激活”状态
                if success {
                    await storeKit.updateCustomerProductStatus()
                }
            }
        }) {
            ZStack {
                if purchasingID != nil {
                    ProgressView().tint(AppTheme.vipBg)
                } else {
                    Text(isCurrentProductActive ? "Current Plan Active" : (userService.isPremium ? "Switch Plan" : "Unlock Pro Features"))
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isCurrentProductActive ? AnyShapeStyle(Color.gray.opacity(0.3)) :
                AnyShapeStyle(LinearGradient(
                    colors: [AppTheme.vipGold, Color(hex: "#FFD700")],
                    startPoint: .leading, endPoint: .trailing
                ))
            )
            .foregroundColor(isCurrentProductActive ? .white.opacity(0.5) : AppTheme.vipBg)
            .clipShape(Capsule())
            .padding(.horizontal, 30)
        }
        .disabled(isCurrentProductActive || purchasingID != nil)
    }

    private var footerLinks: some View {
        VStack(spacing: 8) {
            Text("Cancel anytime. Instant activation.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 12) {
                Button("Terms") {
                    safariURL = URL(string: AIConfig.shared.termsOfServiceURL)
                    showSafari = true
                }
                Text("•")
                Button("Privacy") {
                    safariURL = URL(string: AIConfig.shared.privacyPolicyURL)
                    showSafari = true
                }
                Text("•")
                Button("Restore") {
                    Task { await storeKit.restorePurchases() }
                }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(AppTheme.textMuted)
        }
    }
}
