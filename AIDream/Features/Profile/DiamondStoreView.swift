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
        let price: String      // 降级显示
        let bonus: Int
        let tag: String?
        let gradient: [Color]
        var totalDiamonds: Int { diamonds + bonus }
    }

    private let packages: [DiamondPackage] = [
        DiamondPackage(
            id: "100",
            productID: .diamonds100,
            diamonds: 100, price: "$0.99", bonus: 0, tag: nil,
            gradient: [Color(hex: "#3A3F5C").opacity(0.8), Color(hex: "#2A2D40").opacity(0.8)]
        ),
        DiamondPackage(
            id: "500",
            productID: .diamonds500,
            diamonds: 500, price: "$4.99", bonus: 50, tag: "POPULAR",
            gradient: [Color(hex: "#2D4A7A").opacity(0.8), Color(hex: "#1E3460").opacity(0.8)]
        ),
        DiamondPackage(
            id: "1200",
            productID: .diamonds1200,
            diamonds: 1200, price: "$9.99", bonus: 200, tag: "BEST VALUE",
            gradient: [Color(hex: "#4A2D7A").opacity(0.8), Color(hex: "#2E1A5E").opacity(0.8)]
        ),
        DiamondPackage(
            id: "3000",
            productID: .diamonds3000,
            diamonds: 3000, price: "$19.99", bonus: 800, tag: "WHALE",
            gradient: [Color(hex: "#7A4A2D").opacity(0.8), Color(hex: "#5E2E1A").opacity(0.8)]
        )
    ]

    @State private var purchasingID: String?
    @State private var showPremiumSheet = false

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerView.padding(.top, 10)

                    balanceHeroCard
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    subscriptionSection
                        .padding(.top, 28)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            showPremiumSheet = true
                        }

                    // 钻石充值套餐
                    VStack(alignment: .leading, spacing: 0) {
                        sectionTitle("RECHARGE DIAMONDS")
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                            .padding(.bottom, 16)

                        if storeKit.isLoadingProducts && storeKit.diamondProducts.isEmpty {
                            loadingPlaceholder
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                                spacing: 14
                            ) {
                                ForEach(packages) { pkg in
                                    packageCard(pkg)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // 购买提示
                    if let error = storeKit.purchaseError {
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.error)
                            .padding(.top, 16)
                    }

                    // 恢复购买
                    Button(action: { Task { await storeKit.restorePurchases() } }) {
                        Text("Restore Purchases")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(.top, 20)

                    // 底部说明
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(AppTheme.success)
                                .font(.system(size: 12))
                            Text("Secure Payment · Instant Delivery")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        Text("Diamonds never expire. Use them anytime for AI generation.")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 110)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPremiumSheet) {
            PremiumView()
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

    // MARK: - Loading Placeholder
    private var loadingPlaceholder: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 180)
                    .overlay(
                        ProgressView().tint(AppTheme.accentSecondary)
                    )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .glassStyle(cornerRadius: 20)
            }

            Spacer()

            Text("Diamond Store")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 余额展示卡片
    private var balanceHeroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1A1D4A").opacity(0.4), Color(hex: "#0E1030").opacity(0.2), Color(hex: "#1A1D4A").opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.03))
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.accentPrimary.opacity(0.4), AppTheme.accentSecondary.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 0.5
                )

            Circle()
                .fill(AppTheme.accentPrimary.opacity(0.15))
                .frame(width: 120, height: 120).blur(radius: 40).offset(x: 80, y: -30)
            Circle()
                .fill(AppTheme.accentSecondary.opacity(0.1))
                .frame(width: 80, height: 80).blur(radius: 30).offset(x: -90, y: 40)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR BALANCE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(AppTheme.textMuted)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("💎").font(.system(size: 28))
                        Text("\(userService.diamonds)")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.accentGrad)
                    }
                    Text("Diamonds")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle().fill(AppTheme.accentGrad.opacity(0.15)).frame(width: 64, height: 64)
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.accentGrad)
                }
            }
            .padding(24)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    // MARK: - 订阅会员
    private var subscriptionSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.accentGrad.opacity(0.2)).frame(width: 52, height: 52)
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.accentGrad)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("PRO MEMBERSHIP")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                Text(subtitleForSubscription)
                    .font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
        }
        .padding(18)
        .glassStyle(cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.accentPrimary.opacity(0.25), lineWidth: 1)
        )
    }

    private var subtitleForSubscription: String {
        if userService.isPremium {
            return "You are a PRO member"
        }
        return "Weekly, Monthly or Lifetime"
    }

    // MARK: - 套餐卡片
    private func packageCard(_ pkg: DiamondPackage) -> some View {
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
            VStack(spacing: 0) {
                if let tag = pkg.tag {
                    Text(tag)
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.accentGradH))
                        .padding(.top, -10).padding(.bottom, 12)
                } else {
                    Spacer().frame(height: 16)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("💎").font(.system(size: 16))
                    Text("\(pkg.totalDiamonds)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 2)

                if pkg.bonus > 0 {
                    Text("+\(pkg.bonus) bonus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.success)
                        .padding(.bottom, 10)
                } else {
                    Spacer().frame(height: 10)
                }

                Group {
                    if isBuying {
                        ProgressView().tint(.white)
                    } else {
                        Text(skProduct?.displayPrice ?? pkg.price)
                            .font(.system(size: 22, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .padding(.bottom, 16)

                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, AppTheme.accentPrimary.opacity(0.3), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1).padding(.horizontal, 12)

                if let product = skProduct {
                    let priceValue = NSDecimalNumber(decimal: product.price).doubleValue
                    let perDiamond = priceValue / Double(pkg.totalDiamonds)
                    Text("~$\(String(format: "%.3f", perDiamond))/💎")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        .padding(.top, 10).padding(.bottom, 4)
                } else {
                    let priceValue = Double(pkg.price.replacingOccurrences(of: "$", with: "")) ?? 0
                    let perDiamond = priceValue / Double(pkg.totalDiamonds)
                    Text("~$\(String(format: "%.3f", perDiamond))/💎")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        .padding(.top, 10).padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 190)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: pkg.gradient, startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isBuying || purchasingID != nil)
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(2)
            Spacer()
        }
    }
}
