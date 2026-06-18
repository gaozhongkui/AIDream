import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userService = UserService.shared
    @ObservedObject var storeKit = StoreKitService.shared

    @State private var selectedProductID: String = StoreProductID.premiumMonthly.rawValue
    @State private var purchasingID: String?

    @State private var safariURL: URL?
    @State private var showSafari = false

    // MARK: - 特权项
    struct FeatureItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
    }

    private let features = [
        FeatureItem(icon: "bolt.fill", title: "Faster Generation", description: "Priority queue for AI video & image creation"),
        FeatureItem(icon: "sparkles", title: "Unlimited HD", description: "Export your masterpieces in high definition"),
        FeatureItem(icon: "diamond.fill", title: "Monthly Bonus", description: "Get 1,000 bonus diamonds every month"),
        FeatureItem(icon: "crown.fill", title: "Exclusive Styles", description: "Access to premium AI models and art styles")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgPrimary.ignoresSafeArea()

                // 背景光晕
                Circle()
                    .fill(AppTheme.accentPrimary.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -100, y: -200)

                VStack(spacing: 0) {
                    headerView

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            heroSection
                            featuresGrid
                            plansSection
                            purchaseButton
                            footerLinks
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
        }
    }

    // MARK: - UI Components
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            Spacer()
            Button(action: { Task { await storeKit.restorePurchases() } }) {
                Text("Restore")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // 已修改：皇冠颜色统一为 AppTheme.vipGold
                Circle().fill(AppTheme.vipGold.opacity(0.15)).frame(width: 80, height: 80).blur(radius: 10)
                Image(systemName: "crown.fill").font(.system(size: 40)).foregroundColor(AppTheme.vipGold)
            }
            VStack(spacing: 8) {
                Text("Upgrade to PRO").font(.system(size: 32, weight: .black)).foregroundColor(.white)
                Text("Unlock the full potential of AI Dream").font(.system(size: 16)).foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.top, 20)
    }

    private var featuresGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(features) { feature in
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(AppTheme.accentGrad.opacity(0.1)).frame(width: 44, height: 44)
                        Image(systemName: feature.icon).font(.system(size: 18)).foregroundStyle(AppTheme.accentGrad)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        Text(feature.description).font(.system(size: 13)).foregroundColor(AppTheme.textMuted)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var plansSection: some View {
        VStack(spacing: 16) {
            if storeKit.subscriptionProducts.isEmpty {
                fallbackPlans
            } else {
                ForEach(storeKit.subscriptionProducts, id: \.id) { product in
                    planCard(product)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func planCard(_ product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        return Button { selectedProductID = product.id } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Text(product.description).font(.system(size: 13)).foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                Text(product.displayPrice).font(.system(size: 20, weight: .black)).foregroundColor(.white)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20).fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? AppTheme.accentPrimary : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1))
        }.buttonStyle(.plain)
    }

    private var fallbackPlans: some View {
        VStack(spacing: 12) {
            fakePlanCard(title: "Weekly", price: "$4.99", id: StoreProductID.premiumWeekly.rawValue)
            fakePlanCard(title: "Monthly", price: "$12.99", id: StoreProductID.premiumMonthly.rawValue, tag: "POPULAR")
        }
    }

    private func fakePlanCard(title: String, price: String, id: String, tag: String? = nil) -> some View {
        let isSelected = selectedProductID == id
        return Button { selectedProductID = id } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        if let tag = tag {
                            Text(tag).font(.system(size: 10, weight: .black)).padding(.horizontal, 8).padding(.vertical, 2).background(AppTheme.accentGradH).cornerRadius(4)
                        }
                    }
                    Text("Unlock all features").font(.system(size: 13)).foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                Text(price).font(.system(size: 20, weight: .black)).foregroundColor(.white)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20).fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? AppTheme.accentPrimary : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1))
        }.buttonStyle(.plain)
    }

    private var purchaseButton: some View {
        VStack(spacing: 12) {
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
                Text(purchasingID != nil ? "Processing..." : (userService.isPremium ? "Already Subscribed" : "Start My Journey"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.vipBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(AppTheme.vipGold)
                    .cornerRadius(30)
            }
            .disabled(userService.isPremium || purchasingID != nil)
            .padding(.horizontal, 24)
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 24) {
            Button("Terms of Service") {
                safariURL = URL(string: AIConfig.shared.termsOfServiceURL)
                showSafari = true
            }
            Button("Privacy Policy") {
                safariURL = URL(string: AIConfig.shared.privacyPolicyURL)
                showSafari = true
            }
        }
        .font(.system(size: 12))
        .foregroundColor(AppTheme.textMuted)
    }
}
