import SwiftUI
import StoreKit

struct DiamondStoreView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userService = UserService.shared
    @ObservedObject var storeKit = StoreKitService.shared

    // MARK: - 钻石套餐数据
    struct DiamondPackage: Identifiable {
        let id: String
        let productID: StoreProductID
        let diamonds: Int
        let price: String
        let bonus: Int
        let tag: String?
        let icon: String
        let color: Color
        var totalDiamonds: Int { diamonds + bonus }
    }

    private let packages: [DiamondPackage] = [
        DiamondPackage(
            id: "300",
            productID: .diamonds300,
            diamonds: 300, price: "$1.99", bonus: 0, tag: nil,
            icon: "sparkles", color: Color(hex: "#A0AEC0")
        ),
        DiamondPackage(
            id: "900",
            productID: .diamonds1000,
            diamonds: 800, price: "$4.99", bonus: 100, tag: NSLocalizedString("premium_tag_popular", comment: ""),
            icon: "bolt.fill", color: Color(hex: "#4FD1C5")
        ),
        DiamondPackage(
            id: "2000",
            productID: .diamonds2500,
            diamonds: 1800, price: "$9.99", bonus: 200, tag: NSLocalizedString("premium_tag_best_value", comment: ""),
            icon: "flame.fill", color: Color(hex: "#F6AD55")
        ),
        DiamondPackage(
            id: "5000",
            productID: .diamonds6000,
            diamonds: 4000, price: "$19.99", bonus: 1000, tag: NSLocalizedString("premium_tag_whale", comment: ""),
            icon: "crown.fill", color: Color(hex: "#F687B3")
        )
    ]

    @State private var purchasingID: String?
    @State private var showPremiumSheet = false
    @State private var appearAnimation = false

    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            AppTheme.bgPrimary.ignoresSafeArea()

            // 装饰性光晕
            Circle()
                .fill(AppTheme.accentPrimary.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(y: -150)

            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        balanceHeroSection
                            .padding(.top, 10)

                        subscriptionBanner

                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(title: NSLocalizedString("label_diamond_packs", comment: ""), subtitle: NSLocalizedString("label_recharge_subtitle", comment: ""))

                            VStack(spacing: 12) {
                                ForEach(packages) { pkg in
                                    packageRow(pkg)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        footerSection
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appearAnimation = true
            }
        }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumView()
        }
    }

    // MARK: - Components

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            Spacer()
            Text(NSLocalizedString("btn_recharge", comment: ""))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button(action: { Task { await storeKit.restorePurchases() } }) {
                Text(NSLocalizedString("btn_restore", comment: ""))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .frame(height: 54)
    }

    private var balanceHeroSection: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("label_current_balance", comment: ""))
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textMuted)
            
            HStack(spacing: 12) {
                Text("💎")
                    .font(.system(size: 32))
                Text("\(userService.diamonds)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .scaleEffect(appearAnimation ? 1.0 : 0.9)

            Text(NSLocalizedString("label_diamond_hero_tip", comment: ""))
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.vertical, 20)
    }

    private var subscriptionBanner: some View {
        Button {
            showPremiumSheet = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.vipGrad.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.vipGrad)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("label_pro_membership", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(NSLocalizedString("label_membership_bonus_tip", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.vipGrad.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textMuted)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func packageRow(_ pkg: DiamondPackage) -> some View {
        let skProduct = storeKit.diamondProducts.first { $0.id == pkg.productID.rawValue }
        let isBuying = purchasingID == pkg.productID.rawValue

        return Button {
            if let product = skProduct {
                purchasingID = product.id
                Task {
                    _ = await storeKit.purchase(product)
                    purchasingID = nil
                }
            }
        } label: {
            HStack(spacing: 16) {
                // Icon Tier
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(pkg.color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: pkg.icon)
                        .font(.system(size: 20))
                        .foregroundColor(pkg.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("\(pkg.totalDiamonds)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(NSLocalizedString("label_diamonds", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    if pkg.bonus > 0 {
                        Text(String(format: NSLocalizedString("label_includes_bonus", comment: ""), pkg.bonus))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.success)
                    }
                }

                Spacer()

                // Price Button
                ZStack {
                    if isBuying {
                        ProgressView().tint(.white)
                    } else {
                        Text(skProduct?.displayPrice ?? pkg.price)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 80, height: 36)
                .background(pkg.tag != nil ? AppTheme.accentPrimary : Color.white.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Group {
                        if let tag = pkg.tag {
                            Text(tag)
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .clipShape(Capsule())
                                .offset(y: -22)
                        }
                    }
                )
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(pkg.tag != nil ? AppTheme.accentPrimary.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isBuying || purchasingID != nil)
    }

    private var footerSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                footerIconItem(icon: "shield.fill", text: NSLocalizedString("label_footer_secure", comment: ""))
                footerIconItem(icon: "bolt.fill", text: NSLocalizedString("label_footer_instant", comment: ""))
                footerIconItem(icon: "clock.fill", text: NSLocalizedString("label_footer_no_expiry", comment: ""))
            }

            Text(NSLocalizedString("label_diamond_footer_disclaimer", comment: ""))
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 20)
    }

    private func footerIconItem(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textMuted)
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
        }
    }
}
