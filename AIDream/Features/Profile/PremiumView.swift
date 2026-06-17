import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userService = UserService.shared
    @ObservedObject var storeKit = StoreKitService.shared

    @State private var selectedProductID: String = StoreProductID.premiumMonthly.rawValue
    @State private var purchasingID: String?

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
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            // 背景光晕
            Circle()
                .fill(AppTheme.accentPrimary.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            Circle()
                .fill(AppTheme.accentSecondary.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 150, y: 100)

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
        .onAppear {
            // 默认选中第一个可用的订阅或月度
            if let first = storeKit.subscriptionProducts.first {
                selectedProductID = first.id
            }
        }
    }

    // MARK: - Header
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

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGrad.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)

                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.accentGrad)
                    .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 10)
            }

            VStack(spacing: 8) {
                Text("Upgrade to PRO")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)

                Text("Unlock the full potential of AI Dream")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Features Grid
    private var featuresGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(features) { feature in
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.accentGrad.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: feature.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.accentGrad)
                    }

                    VStack(alignment: .leading, spacing: 2) {
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
        .padding(.horizontal, 24)
    }

    // MARK: - Plans Section
    private var plansSection: some View {
        VStack(spacing: 16) {
            if storeKit.isLoadingProducts && storeKit.subscriptionProducts.isEmpty {
                ProgressView().tint(AppTheme.accentSecondary)
            } else {
                ForEach(storeKit.subscriptionProducts, id: \.id) { product in
                    planCard(product)
                }

                // Fallback UI if products aren't loaded yet
                if storeKit.subscriptionProducts.isEmpty {
                    fallbackPlans
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func planCard(_ product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let productType = StoreProductID(rawValue: product.id)

        return Button {
            selectedProductID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(planTitle(for: product.id))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        if productType == .premiumMonthly {
                            Text("POPULAR")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppTheme.accentGradH)
                                .cornerRadius(4)
                        } else if productType == .premiumLifetime {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppTheme.success.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }

                    Text(planSubtitle(for: product.id))
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)

                    if productType != .premiumLifetime {
                        Text("per " + (productType == .premiumWeekly ? "week" : "month"))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            .padding(.all, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? AppTheme.accentPrimary : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var fallbackPlans: some View {
        VStack(spacing: 12) {
            fakePlanCard(title: "Weekly", subtitle: "Try for 7 days", price: "$4.99", type: .premiumWeekly)
            fakePlanCard(title: "Monthly", subtitle: "1,000 bonus diamonds", price: "$12.99", type: .premiumMonthly, tag: "POPULAR")
            fakePlanCard(title: "Lifetime", subtitle: "One-time payment", price: "$59.99", type: .premiumLifetime, tag: "BEST VALUE")
        }
    }

    private func fakePlanCard(title: String, subtitle: String, price: String, type: StoreProductID, tag: String? = nil) -> some View {
        let isSelected = selectedProductID == type.rawValue
        return Button {
            selectedProductID = type.rawValue
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        if let tag = tag {
                            Text(tag)
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(tag == "POPULAR" ? AnyShapeStyle(AppTheme.accentGradH) : AnyShapeStyle(AppTheme.success.opacity(0.8)))
                                .cornerRadius(4)
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                Text(price).font(.system(size: 20, weight: .black)).foregroundColor(.white)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20).fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? AppTheme.accentPrimary : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1))
        }.buttonStyle(.plain)
    }

    private func planTitle(for id: String) -> String {
        switch StoreProductID(rawValue: id) {
        case .premiumWeekly: return "Weekly"
        case .premiumMonthly: return "Monthly"
        case .premiumLifetime: return "Lifetime"
        default: return "Subscription"
        }
    }

    private func planSubtitle(for id: String) -> String {
        switch StoreProductID(rawValue: id) {
        case .premiumWeekly: return "Cancel anytime"
        case .premiumMonthly: return "1,000 bonus diamonds"
        case .premiumLifetime: return "Pay once, enjoy forever"
        default: return ""
        }
    }

    // MARK: - Purchase Button
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
                HStack {
                    if purchasingID != nil {
                        ProgressView().tint(AppTheme.vipBg)
                    } else {
                        Text(userService.isPremium ? "Already Subscribed" : "Get Premium Access")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.vipBg)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#FFE1A8"), Color(hex: "#C8A768"), Color(hex: "#FFE1A8")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: AppTheme.vipGold.opacity(0.4), radius: 15, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
            }
            .disabled(userService.isPremium || purchasingID != nil)
            .padding(.horizontal, 24)

            Text("Auto-renews for the same price until cancelled.")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textMuted)
        }
    }

    // MARK: - Footer Links
    private var footerLinks: some View {
        HStack(spacing: 24) {
            Button("Terms of Service") {}
            Button("Privacy Policy") {}
        }
        .font(.system(size: 12))
        .foregroundColor(AppTheme.textMuted)
    }
}

#Preview {
    PremiumView()
}
